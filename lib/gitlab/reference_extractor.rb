# frozen_string_literal: true

module Gitlab
  # Extract possible GFM references from an arbitrary String for further processing.
  class ReferenceExtractor < Banzai::ReferenceExtractor
    REFERABLES = %i(user issue label milestone mentioned_user mentioned_group mentioned_project
                    merge_request snippet commit commit_range directly_addressed_user epic iteration vulnerability).freeze
    attr_accessor :project, :current_user, :author
    # This counter is increased by a number of references filtered out by
    # banzai reference exctractor. Note that this counter is stateful and
    # not idempotent and is increased whenever you call `references`.
    attr_reader :stateful_not_visible_counter

    def initialize(project, current_user = nil)
      @project = project
      @current_user = current_user
      @references = {}
      @stateful_not_visible_counter = 0

      super()
    end

    def analyze(text, context = {})
      super(text, context.merge(project: project))
    end

    def references(type, ids_only: false)
      refs = super(type, project, current_user, ids_only: ids_only)
      @stateful_not_visible_counter += refs[:not_visible].count

      refs[:visible]
    end

    def reset_memoized_values
      @references = {}
      @stateful_not_visible_counter = 0
      super()
    end

    REFERABLES.each do |type|
      define_method(type.to_s.pluralize) do
        @references[type] ||= references(type)
      end

      if %w(mentioned_user mentioned_group mentioned_project).include?(type.to_s)
        define_method("#{type}_ids") do
          @references[type] ||= references(type, ids_only: true)
        end
      end
    end

    def issues
      if project&.external_references_supported?
        if project.issues_enabled?
          @references[:all_issues] ||= references(:external_issue) + references(:issue)
        else
          @references[:external_issue] ||= references(:external_issue) +
            references(:issue).select { |i| i.project_id != project.id }
        end
      else
        @references[:issue] ||= references(:issue)
      end
    end

    def all
      REFERABLES.each { |referable| send(referable.to_s.pluralize) } # rubocop:disable GitlabSecurity/PublicSend
      @references.values.flatten
    end

    def self.references_pattern
      return @pattern if @pattern

      patterns = REFERABLES.map do |type|
        Banzai::ReferenceParser[type].reference_type.to_s.classify.constantize.try(:reference_pattern)
      end.uniq

      @pattern = Regexp.union(patterns.compact)
    end
  end
end
