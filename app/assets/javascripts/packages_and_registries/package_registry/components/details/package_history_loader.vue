<script>
import { GlSkeletonLoader } from '@gitlab/ui';

export default {
  components: {
    GlSkeletonLoader,
  },
  loader: {
    width: 580,
    height: 80,
  },
};
</script>

<template>
  <div class="gl-ml-5 md:gl-max-w-7/10">
    <gl-skeleton-loader :width="$options.loader.width" :height="$options.loader.height">
      <rect x="49" y="9" width="531" height="16" rx="4" />
      <circle cx="16" cy="16" r="16" />
      <rect x="49" y="57" width="302" height="16" rx="4" />
      <circle cx="16" cy="64" r="16" />
    </gl-skeleton-loader>
  </div>
</template>
