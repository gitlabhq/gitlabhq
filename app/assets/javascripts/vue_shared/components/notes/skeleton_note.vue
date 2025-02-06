<script>
import { GlSkeletonLoader } from '@gitlab/ui';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';

export default {
  name: 'SkeletonNote',
  components: {
    GlSkeletonLoader,
    TimelineEntryItem,
  },
};
</script>

<template>
  <timeline-entry-item class="note note-wrapper">
    <div
      class="gl-float-left -gl-mt-1 gl-ml-2 gl-flex gl-h-6 gl-w-6 gl-items-center gl-justify-center gl-rounded-full gl-bg-strong gl-text-subtle"
    ></div>
    <div class="timeline-content">
      <div class="note-header"></div>
      <div class="note-body gl-mt-4"><gl-skeleton-loader /></div>
    </div>
  </timeline-entry-item>
</template>
