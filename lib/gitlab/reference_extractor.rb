# frozen_string_literal: true

module Gitlab
  # Extract possible GFM references from an arbitrary String for further processing.
  class ReferenceExtractor < Banzai::ReferenceExtractor
    REFERABLES = %i[user issue work_item label milestone mentioned_user mentioned_group mentioned_project
                    merge_request snippet commit commit_range directly_addressed_user epic vulnerability
                    alert].freeze
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

    def references(type, ids_only: false)
      refs = super(type, project, current_user, ids_only: ids_only)
      update_visible_nodes_set(refs[:nodes], refs[:visible_nodes])

      refs[:visible]
    end

    # this method is stateful, it tracks if all nodes from `references`
    # calls are visible or not
    def all_visible?
      not_visible_nodes.empty?
    end

    def reset_memoized_values
      @references = {}
      super()
    end

    REFERABLES.each do |type|
      define_method(type.to_s.pluralize) do
        @references[type] ||= references(type)
      end

      next unless %w[mentioned_user mentioned_group mentioned_project].include?(type.to_s)

      define_method("#{type}_ids") do
        @references[type] ||= references(type, ids_only: true)
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
      self.class.referrables.each { |referable| send(referable.to_s.pluralize) } # rubocop:disable GitlabSecurity/PublicSend
      @references.values.flatten
    end

    class << self
      def references_pattern
        return @pattern if @pattern

        patterns = referrables.map do |type|
          Banzai::ReferenceParser[type].reference_class.try(:reference_pattern)
        end.uniq

        @pattern = Regexp.union(patterns.compact)
      end

      def referrables
        @referrables ||= REFERABLES
      end
    end

    def has_work_item_references?
      references(:work_item).present?
    end

    private

    def update_visible_nodes_set(all, visible)
      not_visible_nodes.merge(all)
      not_visible_nodes.subtract(visible)
    end

    def not_visible_nodes
      @not_visible_nodes ||= Set.new
    end
  end
end

Gitlab::ReferenceExtractor.prepend_mod
