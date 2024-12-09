# frozen_string_literal: true

module WorkItems
  module ParentLinks
    class BaseService < IssuableLinks::CreateService
      extend ::Gitlab::Utils::Override

      def initialize(issuable, user, params)
        @previous_parents = Set.new
        super
      end

      private

      def set_parent(issuable, work_item)
        link = WorkItems::ParentLink.for_work_item(work_item)
        previous_parents.add(link.work_item_parent) if link.work_item_parent
        link.work_item_parent = issuable
        link
      end

      def create_notes(work_item)
        SystemNoteService.relate_work_item(issuable, work_item, current_user)
      end

      def linkable_issuables(work_items)
        @linkable_issuables ||= if can_add_to_parent?(issuable)
                                  work_items.select { |work_item| linkable?(work_item) }
                                else
                                  []
                                end
      end

      def linkable?(work_item)
        can_admin_link?(work_item) && previous_related_issuables.exclude?(work_item)
      end

      def can_admin_link?(work_item)
        can?(current_user, :admin_parent_link, work_item)
      end

      # Overriden in EE
      def can_add_to_parent?(parent_work_item)
        can_admin_link?(parent_work_item)
      end

      def track_event
        events = previous_parents.map do |previous_parent|
          WorkItems::WorkItemUpdatedEvent.new(data: {
            id: previous_parent.id,
            namespace_id: previous_parent.namespace_id,
            updated_widgets: ['hierarchy_widget']
          })
        end

        Gitlab::EventStore.publish_group(events) if events.any?
      end

      override :previous_related_issuables
      def previous_related_issuables
        @previous_related_issuables ||= issuable.work_item_children.to_a
      end

      override :target_issuable_type
      def target_issuable_type
        'work item'
      end

      override :issuables_not_found_message
      def issuables_not_found_message
        format(_('No matching %{issuable} found. Make sure that you are adding a valid %{issuable} ID.'),
          issuable: target_issuable_type)
      end

      attr_accessor :previous_parents
    end
  end
end

WorkItems::ParentLinks::BaseService.prepend_mod
