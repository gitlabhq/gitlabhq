<script>
import { GlDisclosureDropdown, GlDisclosureDropdownItem, GlTooltipDirective } from '@gitlab/ui';
import { TYPE_INCIDENT, TYPE_ISSUE } from '~/issues/constants';
import { WORK_ITEM_TYPE_NAME_EPIC, WORK_ITEM_TYPE_NAME_ISSUE } from '~/work_items/constants';
import eventHub from '../event_hub';

const allowedTypes = [
  TYPE_INCIDENT,
  TYPE_ISSUE,
  WORK_ITEM_TYPE_NAME_EPIC,
  WORK_ITEM_TYPE_NAME_ISSUE,
];

export default {
  components: {
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['id', 'issuableType', 'enabled'],
  computed: {
    showConvertToTaskItem() {
      return allowedTypes.includes(this.issuableType);
    },
    isEnabledTaskListItem() {
      return this.enabled;
    },
  },
  methods: {
    convertToTask() {
      eventHub.$emit('convert-task-list-item', this.eventPayload());
    },
    deleteTaskListItem() {
      eventHub.$emit('delete-task-list-item', this.eventPayload());
    },
    disableTaskListItem() {
      eventHub.$emit('disable-task-list-item', this.eventPayload());
    },
    enableTaskListItem() {
      eventHub.$emit('enable-task-list-item', this.eventPayload());
    },
    eventPayload() {
      return {
        id: this.id,
        sourcepos: this.$el.closest('li').dataset.sourcepos,
      };
    },
  },
};
</script>

<template>
  <gl-disclosure-dropdown
    v-gl-tooltip.left="s__('WorkItem|Task actions')"
    class="task-list-item-actions-wrapper"
    category="tertiary"
    icon="ellipsis_v"
    no-caret
    placement="bottom-end"
    text-sr-only
    toggle-class="task-list-item-actions gl-opacity-0 !gl-p-2"
    :toggle-text="s__('WorkItem|Task actions')"
  >
    <gl-disclosure-dropdown-item
      v-if="showConvertToTaskItem && isEnabledTaskListItem"
      class="!gl-ml-2"
      data-testid="convert"
      @action="convertToTask"
    >
      <template #list-item>
        {{ s__('WorkItem|Convert to child item') }}
      </template>
    </gl-disclosure-dropdown-item>
    <gl-disclosure-dropdown-item
      v-if="isEnabledTaskListItem"
      class="!gl-ml-2"
      data-testid="disable"
      @action="disableTaskListItem"
    >
      <template #list-item>
        {{ s__('WorkItem|Disable list item') }}
      </template>
    </gl-disclosure-dropdown-item>
    <gl-disclosure-dropdown-item
      v-if="!isEnabledTaskListItem"
      class="!gl-ml-2"
      data-testid="enable"
      @action="enableTaskListItem"
    >
      <template #list-item>
        {{ s__('WorkItem|Enable list item') }}
      </template>
    </gl-disclosure-dropdown-item>
    <gl-disclosure-dropdown-item
      class="!gl-ml-2"
      data-testid="delete"
      variant="danger"
      @action="deleteTaskListItem"
    >
      <template #list-item>{{ __('Delete') }}</template>
    </gl-disclosure-dropdown-item>
  </gl-disclosure-dropdown>
</template>
