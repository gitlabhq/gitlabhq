<script>
import { GlSkeletonLoader } from '@gitlab/ui';

export default {
  components: {
    GlSkeletonLoader,
  },
};
</script>

<template>
  <gl-skeleton-loader :width="350" :height="420">
    <rect width="350" height="16" />
    <rect y="25" width="110" height="16" rx="8" />
    <rect x="115" y="25" width="110" height="16" rx="8" />
    <rect x="230" y="25" width="110" height="16" rx="8" />
    <rect y="50" width="350" height="165" rx="12" />
    <rect y="230" width="480" height="8" />
    <rect y="254" width="560" height="8" />
    <rect y="278" width="320" height="8" />
    <rect y="302" width="480" height="8" />
    <rect y="326" width="560" height="8" />
    <rect y="365" width="80" height="8" />
  </gl-skeleton-loader>
</template>
