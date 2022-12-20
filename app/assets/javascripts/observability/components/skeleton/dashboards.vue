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
    <rect y="2" width="10" height="8" />
    <rect y="2" x="15" width="15" height="8" />
    <rect y="2" x="35" width="15" height="8" />

    <!--  Top right -->
    <rect y="2" x="354" width="10" height="8" />
    <rect y="2" x="366" width="10" height="8" />
    <rect y="2" x="378" width="10" height="8" />
    <rect y="2" x="390" width="10" height="8" />

    <!-- Middle header -->
    <rect y="15" width="400" height="30" rx="2" ry="2" />

    <!-- Dashboard container -->
    <rect y="50" width="200" height="100" rx="2" ry="2" />
  </gl-skeleton-loader>
</template>
