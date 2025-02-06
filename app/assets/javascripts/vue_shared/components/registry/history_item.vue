<script>
import { GlIcon } from '@gitlab/ui';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';

export default {
  name: 'HistoryItem',
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
  <timeline-entry-item class="system-note note-wrapper">
    <div
      class="gl-float-left -gl-mt-1 gl-ml-2 gl-flex gl-h-6 gl-w-6 gl-items-center gl-justify-center gl-rounded-full gl-bg-strong gl-text-subtle"
    >
      <gl-icon :name="icon" />
    </div>
    <div class="timeline-content">
      <div class="note-header">
        <div class="note-header-info">
          <slot></slot>
        </div>
      </div>
      <div class="note-body">
        <slot name="body"></slot>
      </div>
    </div>
  </timeline-entry-item>
</template>
