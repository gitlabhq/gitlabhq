<script>
import { GlSkeletonLoader } from '@gitlab/ui';

export default {
  components: {
    GlSkeletonLoader,
  },
};
</script>
<template>
  <gl-skeleton-loader>
    <rect y="5" width="400" height="30" rx="2" ry="2" />
    <rect y="50" width="400" height="80" rx="2" ry="2" />
  </gl-skeleton-loader>
</template>
