<script>
import { GlSkeletonLoader } from '@gitlab/ui';

export default {
  components: {
    GlSkeletonLoader,
  },
};
</script>
<template>
  <gl-skeleton-loader :height="200">
    <!-- Top header-->
    <rect y="2" width="400" height="30" />

    <rect y="35" x="65" width="80" height="8" />
    <rect y="35" x="205" width="30" height="8" />
    <rect y="35" x="240" width="25" height="8" />
    <rect y="35" x="270" width="20" height="8" />

    <rect y="55" x="65" width="100" height="8" />
    <rect y="55" x="225" width="65" height="8" />

    <rect y="65" x="65" width="225" height="200" rx="2" ry="2" />
  </gl-skeleton-loader>
</template>
