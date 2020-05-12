<script>
import { GlSkeletonLoader } from '@gitlab/ui';

export default {
  components: {
    GlSkeletonLoader,
  },
};
</script>
<template>
  <gl-skeleton-loader :width="500" :height="102">
    <rect width="500" height="16" rx="4" />
    <rect y="20" width="375" height="16" rx="4" />
    <rect x="380" y="20" width="120" height="16" rx="4" />
    <rect y="40" width="250" height="16" rx="4" />
    <rect x="255" y="40" width="150" height="16" rx="4" />
    <rect x="410" y="40" width="90" height="16" rx="4" />
  </gl-skeleton-loader>
</template>
