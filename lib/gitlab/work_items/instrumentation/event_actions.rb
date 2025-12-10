# frozen_string_literal: true

module Gitlab
  module WorkItems
    module Instrumentation
      module EventActions
        CLONE = 'work_item_clone'
        CLOSE = 'work_item_close'
        DESIGN_NOTE_CREATE = 'work_item_design_note_create'
        DESIGN_NOTE_DESTROY = 'work_item_design_note_destroy'
        MOVE = 'work_item_move'
        NOTE_CREATE = 'work_item_note_create'
        NOTE_DESTROY = 'work_item_note_destroy'
        NOTE_UPDATE = 'work_item_note_update'
        REOPEN = 'work_item_reopen'

        ALL_EVENTS = [
          CLONE,
          CLOSE,
          DESIGN_NOTE_CREATE,
          DESIGN_NOTE_DESTROY,
          MOVE,
          NOTE_CREATE,
          NOTE_DESTROY,
          NOTE_UPDATE,
          REOPEN
        ].freeze

        def self.valid_event?(event)
          ALL_EVENTS.include?(event)
        end
      end
    end
  end
end
