<script>
import { GlSkeletonLoader } from '@gitlab/ui';

export default {
  components: {
    GlSkeletonLoader,
  },
};
</script>

<template>
  <gl-skeleton-loader :width="737" :height="48">
    <rect width="24" height="24" y="12" x="8" />
    <rect width="120" height="12" y="10" x="36" />
    <rect width="100" height="12" y="26" x="36" />
  </gl-skeleton-loader>
</template>
