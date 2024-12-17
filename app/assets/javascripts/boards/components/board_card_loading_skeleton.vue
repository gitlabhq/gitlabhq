<script>
import { GlSkeletonLoader } from '@gitlab/ui';

export default {
  name: 'BoardCardLoading',
  components: {
    GlSkeletonLoader,
  },
};
</script>

<template>
  <div
    class="board-card-skeleton gl-mb-3 gl-rounded-base gl-border-1 gl-border-solid gl-border-subtle gl-bg-white gl-p-5"
  >
    <div class="board-card-skeleton-inner">
      <gl-skeleton-loader :width="340" :height="100">
        <rect width="340" height="16" rx="4" />
        <rect y="30" width="118" height="16" rx="8" />
        <rect x="122" y="30" width="130" height="16" rx="8" />
        <rect y="62" width="38" height="16" rx="4" />
        <circle cx="320" cy="68" r="16" />
      </gl-skeleton-loader>
    </div>
  </div>
</template>
