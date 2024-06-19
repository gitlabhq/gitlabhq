# frozen_string_literal: true

module WorkItems
  class ResourceLinkEvent < ResourceEvent
    belongs_to :child_work_item, class_name: 'WorkItem'

    validates :child_work_item, presence: true

    enum action: {
      add: 1,
      remove: 2
    }

    def synthetic_note_class
      nil
    end
  end
end

WorkItems::ResourceLinkEvent.prepend_mod
