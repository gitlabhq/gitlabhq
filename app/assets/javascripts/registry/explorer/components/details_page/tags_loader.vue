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
      <rect width="15" x="0" y="12.5" height="15" rx="4" />
      <rect width="250" x="25" y="10" height="20" rx="4" />
      <circle cx="290" cy="20" r="10" />
      <rect width="100" x="315" y="10" height="20" rx="4" />
      <rect width="100" x="500" y="10" height="20" rx="4" />
      <rect width="100" x="630" y="10" height="20" rx="4" />
      <rect x="960" y="0" width="40" height="40" rx="4" />
    </gl-skeleton-loader>
  </div>
</template>
