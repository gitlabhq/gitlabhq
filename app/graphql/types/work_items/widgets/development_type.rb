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

        field :related_merge_requests,
          Types::WorkItems::RelatedMergeRequestType.connection_type,
          null: true,
          description: 'Merge requests related to the work item.'

        def related_merge_requests
          if object.related_merge_requests.loaded?
            object.related_merge_requests
          else
            object.related_merge_requests.preload_merge_request_for_authorization
          end
        end
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end

Types::WorkItems::Widgets::DevelopmentType.prepend_mod
