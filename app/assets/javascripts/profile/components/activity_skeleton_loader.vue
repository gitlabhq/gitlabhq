<script>
import { GlSkeletonLoader } from '@gitlab/ui';

export default {
  name: 'ActivitySkeletonLoader',
  components: { GlSkeletonLoader },
  props: {
    count: {
      type: Number,
      required: false,
      default: 3,
    },
  },
};
</script>

<template>
  <div class="gl-flex gl-flex-col gl-gap-5" data-testid="activities-skeleton">
    <gl-skeleton-loader
      v-for="n in count"
      :key="n"
      :width="1000"
      :height="40"
      preserve-aspect-ratio="xMinYMid meet"
    >
      <!-- icon -->
      <circle cx="12" cy="20" r="12" />
      <!-- title -->
      <rect x="40" y="9" width="520" height="12" rx="4" />
      <!-- timestamp -->
      <rect x="880" y="10" width="120" height="10" rx="4" />
      <!-- description -->
      <rect x="40" y="26" width="360" height="10" rx="4" />
    </gl-skeleton-loader>
  </div>
</template>
