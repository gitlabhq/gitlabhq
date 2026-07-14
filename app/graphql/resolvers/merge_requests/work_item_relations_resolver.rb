# frozen_string_literal: true

module Resolvers
  module MergeRequests
    class WorkItemRelationsResolver < BaseResolver
      type ::Types::MergeRequests::WorkItemRelationType.connection_type, null: true

      argument :types, [::Types::MergeRequests::WorkItemLinkTypeEnum],
        required: false,
        description: 'Filter by link types. Returns all types if not specified.'

      # Preload what the per-row read_merge_request_closing_issue policy reads, to avoid N+1.
      before_connection_authorization do |relations, _current_user|
        ActiveRecord::Associations::Preloader.new(
          records: relations,
          associations: [{ issue: :project }, { merge_request: :target_project }]
        ).call
      end

      def resolve(types: nil)
        return unless Feature.enabled?(:explicit_mr_work_item_relations, object.project)

        relations = object.merge_request_issues
        relations = relations.by_link_types(types) if types.present?
        relations
      end
    end
  end
end
