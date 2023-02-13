<script>
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import eventHub from '../event_hub';

export default {
  i18n: {
    convertToTask: s__('WorkItem|Convert to task'),
    delete: __('Delete'),
    taskActions: s__('WorkItem|Task actions'),
  },
  components: {
    GlDropdown,
    GlDropdownItem,
  },
  inject: ['canUpdate', 'toggleClass'],
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
  <gl-dropdown
    class="task-list-item-actions-wrapper"
    category="tertiary"
    icon="ellipsis_v"
    lazy
    no-caret
    right
    :text="$options.i18n.taskActions"
    text-sr-only
    :toggle-class="`task-list-item-actions gl-opacity-0 gl-p-2! ${toggleClass}`"
  >
    <gl-dropdown-item v-if="canUpdate" @click="convertToTask">
      {{ $options.i18n.convertToTask }}
    </gl-dropdown-item>
    <gl-dropdown-item v-if="canUpdate" variant="danger" @click="deleteTaskListItem">
      {{ $options.i18n.delete }}
    </gl-dropdown-item>
  </gl-dropdown>
</template>
