<script>
import { GlIcon } from '@gitlab/ui';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';

export default {
  name: 'HistoryElement',
  components: {
    GlIcon,
    TimelineEntryItem,
  },

  props: {
    icon: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <timeline-entry-item class="system-note note-wrapper gl-my-6!">
    <div class="timeline-icon">
      <gl-icon :name="icon" />
    </div>
    <div class="timeline-content">
      <div class="note-header">
        <span>
          <slot></slot>
        </span>
      </div>
      <div class="note-body"></div>
    </div>
  </timeline-entry-item>
</template>
