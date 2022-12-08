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
    <!--  Top left -->
    <circle y="2" cx="6" cy="6" r="4" />
    <rect y="2" x="15" width="15" height="8" />
    <rect y="2" x="35" width="40" height="8" />

    <!--  Top right -->

    <rect y="2" x="263" width="13" height="8" />
    <rect y="2" x="278" width="8" height="8" />
    <rect y="2" x="288" width="50" height="8" />
    <rect y="2" x="340" width="18" height="8" />
    <rect y="2" x="360" width="30" height="8" />

    <rect y="15" width="400" height="30" rx="2" ry="2" />
  </gl-skeleton-loader>
</template>
