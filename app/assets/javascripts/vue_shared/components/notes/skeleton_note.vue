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
      class="gl-float-left gl-flex gl-justify-center gl-items-center gl-rounded-full -gl-mt-1 gl-ml-2 gl-w-6 gl-h-6 gl-bg-gray-50 gl-text-gray-600"
    ></div>
    <div class="timeline-content">
      <div class="note-header"></div>
      <div class="note-body gl-mt-4"><gl-skeleton-loader /></div>
    </div>
  </timeline-entry-item>
</template>
