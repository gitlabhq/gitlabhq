# frozen_string_literal: true

module WorkItemResourceEvent
  extend ActiveSupport::Concern

  included do
    belongs_to :work_item, foreign_key: 'issue_id'

    scope :with_work_item, -> { preload(:work_item) }

    # These events are created also on non work items, e.g. MRs, Epic however system notes subscription
    # is only implemented on work items, so we do check if this event is linked to an work item. This can be
    # expanded to other issuables later on.
    after_commit :trigger_note_subscription_create, on: :create, if: -> { work_item.present? }
  end

  # System notes are not updated or deleted, so firing just the noteCreated event.
  def trigger_note_subscription_create(events: self)
    GraphqlTriggers.work_item_note_created(work_item.to_gid, events)
  end

  def work_item_synthetic_system_note(events: nil)
    return unless synthetic_note_class

    # System notes for label resource events are handled in batches,
    # so that we have single system note for multiple label changes.
    if is_a?(ResourceLabelEvent) && events.present?
      return synthetic_note_class.from_events(events, resource: work_item, resource_parent: work_item.project)
    end

    synthetic_note_class.from_event(self, resource: work_item, resource_parent: work_item.project)
  end

  # Class used to create the even synthetic note
  # If the event does not require a synthetic note the method must return false
  def synthetic_note_class
    raise NoMethodError, <<~MESSAGE.squish
      `#{self.class.name}#synthetic_note_class` method must be implemented
      (return nil if event does not require a note)
    MESSAGE
  end
end
