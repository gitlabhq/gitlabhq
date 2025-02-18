# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      # Disabling widget level authorization as it might be too granular
      # and we already authorize the parent work item
      # rubocop:disable Graphql/AuthorizeTypes -- reason above
      class DevelopmentType < BaseObject
        graphql_name 'WorkItemWidgetDevelopment'
        description 'Represents a development widget'

        implements ::Types::WorkItems::WidgetInterface

        field :closing_merge_requests,
          ::Types::WorkItems::ClosingMergeRequestType.connection_type,
          null: true,
          description: 'Merge requests that will close the work item when merged.'
        field :related_branches,
          ::Types::WorkItems::RelatedBranchType.connection_type,
          calls_gitaly: true,
          description: 'Branches that have referred to the work item, but do not have an associated merge request.',
          null: true do
            extension ::Gitlab::Graphql::Limit::FieldCallCount, limit: 1
          end
        field :related_merge_requests, # rubocop:disable GraphQL/ExtractType -- no need to extract to related
          ::Types::MergeRequestType.connection_type,
          null: true,
          resolver: ::Resolvers::MergeRequests::WorkItemRelatedResolver,
          description: 'Merge requests where the work item has been mentioned. ' \
            'This field can only be resolved for one work item in any single request.',
          experiment: { milestone: '17.6' } do
            extension ::Gitlab::Graphql::Limit::FieldCallCount, limit: 1
          end
        field :will_auto_close_by_merge_request,
          GraphQL::Types::Boolean,
          null: false,
          description: 'Whether the work item will automatically be closed when a closing merge request is merged.'

        def related_branches
          return [] unless object.work_item.project

          ::Issues::RelatedBranchesService
            .new(container: object.work_item.project, current_user: current_user)
            .execute(object.work_item)
        end

        def closing_merge_requests
          if object.closing_merge_requests.loaded?
            object.closing_merge_requests
          else
            object.closing_merge_requests.preload_merge_request_for_authorization
          end
        end
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end

Types::WorkItems::Widgets::DevelopmentType.prepend_mod
