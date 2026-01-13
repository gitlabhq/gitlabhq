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

        ASSIGNEES_UPDATE = 'work_item_assignees_update'
        BLOCKED_BY_ITEM_ADD = 'work_item_blocked_by_item_add'
        BLOCKED_BY_ITEM_REMOVE = 'work_item_blocked_by_item_remove'
        BLOCKING_ITEM_ADD = 'work_item_blocking_item_add'
        BLOCKING_ITEM_REMOVE = 'work_item_blocking_item_remove'
        CLONE = 'work_item_clone'
        CLOSE = 'work_item_close'
        CONFIDENTIALITY_DISABLE = 'work_item_confidentiality_disable'
        CONFIDENTIALITY_ENABLE = 'work_item_confidentiality_enable'
        CREATE = 'work_item_create'
        CREATE_CHILD_ITEMS_WIDGET = 'work_item_create_child_items_widget'
        CREATE_GLOBAL_NAV = 'work_item_create_global_nav'
        CREATE_VULNERABILITY = 'work_item_create_vulnerability'
        CREATE_WORK_ITEM_LIST = 'work_item_create_work_item_list'
        DESCRIPTION_UPDATE = 'work_item_description_update'
        DESIGN_CREATE = 'work_item_design_create'
        DESIGN_DESTROY = 'work_item_design_destroy'
        DESIGN_UPDATE = 'work_item_design_update'
        DESIGN_NOTE_CREATE = 'work_item_design_note_create'
        DESIGN_NOTE_DESTROY = 'work_item_design_note_destroy'
        DUE_DATE_UPDATE = 'work_item_due_date_update'
        HEALTH_STATUS_UPDATE = 'work_item_health_status_update'
        ITERATION_UPDATE = 'work_item_iteration_update'
        LABELS_UPDATE = 'work_item_labels_update'
        LOCK = 'work_item_lock'
        MARKED_AS_DUPLICATE = 'work_item_marked_as_duplicate'
        MILESTONE_UPDATE = 'work_item_milestone_update'
        MOVE = 'work_item_move'
        NOTE_CREATE = 'work_item_note_create'
        NOTE_DESTROY = 'work_item_note_destroy'
        NOTE_UPDATE = 'work_item_note_update'
        REFERENCE_ADD = 'work_item_reference_add'
        RELATED_ITEM_ADD = 'work_item_related_item_add'
        RELATED_ITEM_REMOVE = 'work_item_related_item_remove'
        REOPEN = 'work_item_reopen'
        START_DATE_UPDATE = 'work_item_start_date_update'
        TIME_ESTIMATE_UPDATE = 'work_item_time_estimate_update'
        TIME_SPENT_UPDATE = 'work_item_time_spent_update'
        TITLE_UPDATE = 'work_item_title_update'
        UNLOCK = 'work_item_unlock'
        WEIGHT_UPDATE = 'work_item_weight_update'

        ALL_EVENTS = [
          ASSIGNEES_UPDATE,
          BLOCKED_BY_ITEM_ADD,
          BLOCKED_BY_ITEM_REMOVE,
          BLOCKING_ITEM_ADD,
          BLOCKING_ITEM_REMOVE,
          CLONE,
          CLOSE,
          CONFIDENTIALITY_DISABLE,
          CONFIDENTIALITY_ENABLE,
          CREATE,
          CREATE_CHILD_ITEMS_WIDGET,
          CREATE_GLOBAL_NAV,
          CREATE_VULNERABILITY,
          CREATE_WORK_ITEM_LIST,
          DESCRIPTION_UPDATE,
          DESIGN_CREATE,
          DESIGN_DESTROY,
          DESIGN_UPDATE,
          DESIGN_NOTE_CREATE,
          DESIGN_NOTE_DESTROY,
          DUE_DATE_UPDATE,
          HEALTH_STATUS_UPDATE,
          ITERATION_UPDATE,
          LABELS_UPDATE,
          LOCK,
          MARKED_AS_DUPLICATE,
          MILESTONE_UPDATE,
          MOVE,
          NOTE_CREATE,
          NOTE_DESTROY,
          NOTE_UPDATE,
          REFERENCE_ADD,
          RELATED_ITEM_ADD,
          RELATED_ITEM_REMOVE,
          REOPEN,
          START_DATE_UPDATE,
          TIME_ESTIMATE_UPDATE,
          TIME_SPENT_UPDATE,
          TITLE_UPDATE,
          UNLOCK,
          WEIGHT_UPDATE
        ].freeze

        def self.valid_event?(event)
          ALL_EVENTS.include?(event)
        end
      end
    end
  end
end
