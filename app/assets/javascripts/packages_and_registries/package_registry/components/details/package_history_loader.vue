<script>
import { GlSkeletonLoader } from '@gitlab/ui';

export default {
  components: {
    GlSkeletonLoader,
  },
};
</script>

<template>
  <div class="gl-my-5 gl-ml-2 gl-flex gl-h-11 gl-max-w-30 gl-flex-col gl-gap-5">
    <div class="-gl-mt-1">
      <gl-skeleton-loader :width="240" :height="64">
        <circle cx="12" cy="12" r="12" />
        <rect x="32" y="4" :width="208" height="16" rx="4" />
        <circle cx="12" cy="52" r="12" />
        <rect x="32" y="44" :width="200" height="16" rx="4" />
      </gl-skeleton-loader>
    </div>
  </div>
</template>
