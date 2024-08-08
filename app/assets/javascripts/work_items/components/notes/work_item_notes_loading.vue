<script>
import { GlSkeletonLoader } from '@gitlab/ui';

export default {
  components: {
    GlSkeletonLoader,
  },
  loader: {
    repeat: 10,
    width: 1000,
    height: 40,
  },
};
</script>

<template>
  <div>
    <gl-skeleton-loader
      v-for="index in $options.loader.repeat"
      :key="index"
      :width="$options.loader.width"
      :height="$options.loader.height"
      preserve-aspect-ratio="xMinYMax meet"
    >
      <circle cx="20" cy="20" r="16" />
      <rect width="512" x="45" y="15" height="10" rx="4" />
    </gl-skeleton-loader>
  </div>
</template>
