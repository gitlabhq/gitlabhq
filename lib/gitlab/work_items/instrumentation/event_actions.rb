# frozen_string_literal: true

module Gitlab
  module WorkItems
    module Instrumentation
      module EventActions
        def self.link_event(link, work_item, action)
          return unless [:add, :remove].include?(action)

          # rubocop:disable Gitlab/NoCodeCoverageComment -- false positive as link_type is restriced to blocks/relates_to by model
          # :nocov:
          base_event = if link.link_type == 'relates_to'
                         'RELATED_ITEM'
                       elsif link.link_type == 'blocks'
                         if link.source_id == work_item.id
                           'BLOCKING_ITEM'
                         elsif link.target_id == work_item.id
                           'BLOCKED_BY_ITEM'
                         end
                       end

          return unless base_event

          # :nocov:
          # rubocop:enable Gitlab/NoCodeCoverageComment

          const_get("#{base_event}_#{action.to_s.upcase}", false)
        end

        BLOCKED_BY_ITEM_ADD = 'work_item_blocked_by_item_add'
        BLOCKED_BY_ITEM_REMOVE = 'work_item_blocked_by_item_remove'
        BLOCKING_ITEM_ADD = 'work_item_blocking_item_add'
        BLOCKING_ITEM_REMOVE = 'work_item_blocking_item_remove'
        CLONE = 'work_item_clone'
        CLOSE = 'work_item_close'
        DESIGN_CREATE = 'work_item_design_create'
        DESIGN_DESTROY = 'work_item_design_destroy'
        DESIGN_UPDATE = 'work_item_design_update'
        DESIGN_NOTE_CREATE = 'work_item_design_note_create'
        DESIGN_NOTE_DESTROY = 'work_item_design_note_destroy'
        MOVE = 'work_item_move'
        NOTE_CREATE = 'work_item_note_create'
        NOTE_DESTROY = 'work_item_note_destroy'
        NOTE_UPDATE = 'work_item_note_update'
        REFERENCE_ADD = 'work_item_reference_add'
        RELATED_ITEM_ADD = 'work_item_related_item_add'
        RELATED_ITEM_REMOVE = 'work_item_related_item_remove'
        REOPEN = 'work_item_reopen'

        ALL_EVENTS = [
          BLOCKED_BY_ITEM_ADD,
          BLOCKED_BY_ITEM_REMOVE,
          BLOCKING_ITEM_ADD,
          BLOCKING_ITEM_REMOVE,
          CLONE,
          CLOSE,
          DESIGN_CREATE,
          DESIGN_DESTROY,
          DESIGN_UPDATE,
          DESIGN_NOTE_CREATE,
          DESIGN_NOTE_DESTROY,
          MOVE,
          NOTE_CREATE,
          NOTE_DESTROY,
          NOTE_UPDATE,
          REFERENCE_ADD,
          RELATED_ITEM_ADD,
          RELATED_ITEM_REMOVE,
          REOPEN
        ].freeze

        def self.valid_event?(event)
          ALL_EVENTS.include?(event)
        end
      end
    end
  end
end
