# frozen_string_literal: true

module BulkImports
  class SourceUrlBuilder
    ALLOWED_RELATIONS = %w[
      issues
      merge_requests
      epics
      milestones
    ].freeze

    attr_reader :context, :entity, :entry

    # @param [BulkImports::Pipeline::Context] context
    # @param [ApplicationRecord] entry
    def initialize(context, entry)
      @context = context
      @entity = context.entity
      @entry = entry
    end

    # Builds a source URL for the given entry if iid is present
    def url
      return unless entry.is_a?(ApplicationRecord)
      return unless iid
      return unless ALLOWED_RELATIONS.include?(relation)

      File.join(source_instance_url, group_prefix, source_full_path, '-', relation, iid.to_s)
    end

    private

    def iid
      @iid ||= entry.try(:iid)
    end

    def relation
      @relation ||= context.tracker.pipeline_class.relation
    end

    def source_instance_url
      @source_instance_url ||= context.bulk_import.configuration.url
    end

    def source_full_path
      @source_full_path ||= entity.source_full_path
    end

    # Group milestone (or epic) url is /groups/:group_path/-/milestones/:iid
    # Project milestone url is /:project_path/-/milestones/:iid
    def group_prefix
      return '' if entity.project?

      entity.pluralized_name
    end
  end
end
