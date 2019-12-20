# frozen_string_literal: true

module Gitlab
  # Extract possible GFM references from an arbitrary String for further processing.
  class ReferenceExtractor < Banzai::ReferenceExtractor
    REFERABLES = %i(user issue label milestone mentioned_user mentioned_group mentioned_project
                    merge_request snippet commit commit_range directly_addressed_user epic).freeze
    attr_accessor :project, :current_user, :author

    def initialize(project, current_user = nil)
      @project = project
      @current_user = current_user
      @references = {}

      super()
    end

    def analyze(text, context = {})
      super(text, context.merge(project: project))
    end

    def references(type)
      super(type, project, current_user)
    end

    def reset_memoized_values
      @references = {}
      super()
    end

    REFERABLES.each do |type|
      define_method("#{type}s") do
        @references[type] ||= references(type)
      end
    end

    def issues
      if project && project.jira_tracker?
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
