# frozen_string_literal: true

module Namespaces
  module Groups
    module ArchiveEvents
      def publish_events
        publish_group_archived_event
      end

      def publish_group_archived_event
        event = Namespaces::Groups::GroupArchivedEvent.new(data: {
          group_id: group.id,
          root_namespace_id: group.root_ancestor.id
        })

        Gitlab::EventStore.publish(event)
      end
    end
  end
end
