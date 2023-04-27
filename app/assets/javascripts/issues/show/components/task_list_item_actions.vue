<script>
import { GlDisclosureDropdown, GlDisclosureDropdownItem } from '@gitlab/ui';
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
  inject: ['canUpdate'],
  methods: {
    convertToTask() {
      eventHub.$emit('convert-task-list-item', this.$el.closest('li').dataset.sourcepos);
      this.closeDropdown();
    },
    deleteTaskListItem() {
      eventHub.$emit('delete-task-list-item', this.$el.closest('li').dataset.sourcepos);
      this.closeDropdown();
    },
    closeDropdown() {
      this.$refs.dropdown.close();
    },
  },
};
</script>

<template>
  <gl-disclosure-dropdown
    v-if="canUpdate"
    ref="dropdown"
    class="task-list-item-actions-wrapper"
    category="tertiary"
    icon="ellipsis_v"
    no-caret
    placement="right"
    :toggle-text="$options.i18n.taskActions"
    text-sr-only
    toggle-class="task-list-item-actions gl-opacity-0 gl-p-2! "
  >
    <gl-disclosure-dropdown-item class="gl-ml-2!" @action="convertToTask">
      <template #list-item>
        {{ $options.i18n.convertToTask }}
      </template>
    </gl-disclosure-dropdown-item>
    <gl-disclosure-dropdown-item class="gl-ml-2!" @action="deleteTaskListItem">
      <template #list-item>
        <span class="gl-text-red-500!">{{ $options.i18n.delete }}</span>
      </template>
    </gl-disclosure-dropdown-item>
  </gl-disclosure-dropdown>
</template>
