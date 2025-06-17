<script>
import { GlSkeletonLoader } from '@gitlab/ui';

export default {
  components: {
    GlSkeletonLoader,
  },
};
</script>

<template>
  <gl-skeleton-loader :width="737" :height="40">
    <rect width="20" height="20" y="12" x="8" :rx="4" />
    <rect width="30%" height="12" y="16" x="40" :rx="4" />
  </gl-skeleton-loader>
</template>
