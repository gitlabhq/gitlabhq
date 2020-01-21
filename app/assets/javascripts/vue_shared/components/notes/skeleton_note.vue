<script>
import { GlSkeletonLoading } from '@gitlab/ui';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';

export default {
  name: 'SkeletonNote',
  components: {
    GlSkeletonLoading,
    TimelineEntryItem,
  },
};
</script>

<template>
  <timeline-entry-item class="note note-wrapper" data-qa-selector="skeleton_note">
    <div class="timeline-icon"></div>
    <div class="timeline-content">
      <div class="note-header"></div>
      <div class="note-body"><gl-skeleton-loading /></div>
    </div>
  </timeline-entry-item>
</template>
