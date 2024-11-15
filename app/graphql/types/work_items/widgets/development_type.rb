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

        implements Types::WorkItems::WidgetInterface

        field :closing_merge_requests,
          Types::WorkItems::ClosingMergeRequestType.connection_type,
          null: true,
          description: 'Merge requests that will close the work item when merged.'
        field :related_branches, # rubocop:disable GraphQL/ExtractType -- no need to extract to related
          Types::WorkItems::RelatedBranchType.connection_type,
          calls_gitaly: true,
          description: 'Branches that have referred to the work item, but do not have an associated merge request.',
          null: true do
            extension ::Gitlab::Graphql::Limit::FieldCallCount, limit: 1
          end
        field :related_merge_requests, # rubocop:disable GraphQL/ExtractType -- no need to extract to related
          Types::MergeRequestType.connection_type,
          null: true,
          description: 'Merge requests where the work item has been mentioned. Not implemented, returns empty list.',
          experiment: { milestone: '17.6' }
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

        # Adding as empty list first to make the field available in next release
        #  TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/503834
        def related_merge_requests
          MergeRequest.none
        end
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end

Types::WorkItems::Widgets::DevelopmentType.prepend_mod
