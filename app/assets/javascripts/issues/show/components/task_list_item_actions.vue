<script>
import { GlDisclosureDropdown, GlDisclosureDropdownItem } from '@gitlab/ui';
import { TYPE_INCIDENT, TYPE_ISSUE } from '~/issues/constants';
import { __, s__ } from '~/locale';
import eventHub from '../event_hub';

export default {
  i18n: {
    convertToTask: s__('WorkItem|Convert to task'),
    delete: __('Delete'),
    taskActions: s__('WorkItem|Task actions'),
  },
  components: {
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
  },
  inject: ['canUpdate', 'issuableType'],
  computed: {
    showConvertToTaskItem() {
      return [TYPE_INCIDENT, TYPE_ISSUE].includes(this.issuableType);
    },
  },
  methods: {
    convertToTask() {
      eventHub.$emit('convert-task-list-item', this.$el.closest('li').dataset.sourcepos);
    },
    deleteTaskListItem() {
      eventHub.$emit('delete-task-list-item', this.$el.closest('li').dataset.sourcepos);
    },
  },
};
</script>

<template>
  <gl-disclosure-dropdown
    v-if="canUpdate"
    class="task-list-item-actions-wrapper"
    category="tertiary"
    icon="ellipsis_v"
    no-caret
    placement="right"
    :toggle-text="$options.i18n.taskActions"
    text-sr-only
    toggle-class="task-list-item-actions gl-opacity-0 gl-p-2! "
  >
    <gl-disclosure-dropdown-item
      v-if="showConvertToTaskItem"
      class="gl-ml-2!"
      data-testid="convert"
      @action="convertToTask"
    >
      <template #list-item>
        {{ $options.i18n.convertToTask }}
      </template>
    </gl-disclosure-dropdown-item>
    <gl-disclosure-dropdown-item class="gl-ml-2!" data-testid="delete" @action="deleteTaskListItem">
      <template #list-item>
        <span class="gl-text-red-500!">{{ $options.i18n.delete }}</span>
      </template>
    </gl-disclosure-dropdown-item>
  </gl-disclosure-dropdown>
</template>
