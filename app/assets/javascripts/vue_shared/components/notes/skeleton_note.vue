<script>
import { GlSkeletonLoading } from '@gitlab/ui';

export default {
  name: 'SkeletonNote',
  components: {
    GlSkeletonLoading,
  },
};
</script>

<template>
  <li class="timeline-entry note note-wrapper">
    <div class="timeline-entry-inner">
      <div class="timeline-icon"></div>
      <div class="timeline-content">
        <div class="note-header"></div>
        <div class="note-body"><gl-skeleton-loading /></div>
      </div>
    </div>
  </li>
</template>
