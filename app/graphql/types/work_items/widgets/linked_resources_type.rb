# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      # Disabling widget level authorization as it might be too granular
      # and we already authorize the parent work item
      # rubocop:disable Graphql/AuthorizeTypes -- reason above
      class LinkedResourcesType < BaseObject
        graphql_name 'WorkItemWidgetLinkedResources'
        description 'Represents the linked resources widget'

        implements ::Types::WorkItems::WidgetInterface

        # linked_resources currently exposes zoom_meetings records associated with the work item.
        # The plan is to make this field more generic in the future as we already have another source
        # of linked_resources associated with the issues table. More details in
        # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/174793#note_2256696898
        field :linked_resources,
          ::Types::WorkItems::LinkedResourceType.connection_type,
          null: true,
          description: 'Resources for the work item.',
          method: :zoom_meetings
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end
