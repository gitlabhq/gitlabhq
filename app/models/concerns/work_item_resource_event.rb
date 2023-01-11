# frozen_string_literal: true

module WorkItemResourceEvent
  extend ActiveSupport::Concern

  included do
    belongs_to :work_item, foreign_key: 'issue_id'
  end

  def work_item_synthetic_system_note(events: nil)
    # System notes for label resource events are handled in batches, so that we have single system note for multiple
    # label changes.
    if is_a?(ResourceLabelEvent) && events.present?
      return synthetic_note_class.from_events(events, resource: work_item, resource_parent: work_item.project)
    end

    synthetic_note_class.from_event(self, resource: work_item, resource_parent: work_item.project)
  end

  def synthetic_note_class
    raise NoMethodError, 'must implement `synthetic_note_class` method'
  end
end
