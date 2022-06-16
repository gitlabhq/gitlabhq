<script>
import { GlSkeletonLoader } from '@gitlab/ui';

export default {
  components: {
    GlSkeletonLoader,
  },
  loader: {
    width: 302,
    height: 16,
    repeat: 2,
  },
};
</script>

<template>
  <div class="gl-bg-gray-50 gl-inset-border-1-gray-100 gl-rounded-base">
    <div
      v-for="index in $options.loader.repeat"
      :key="index"
      class="gl-display-flex gl-align-items-center gl-p-4 gl-border-gray-100 gl-border-b-1"
    >
      <div class="gl-md-max-w-30p">
        <gl-skeleton-loader :width="$options.loader.width" :height="$options.loader.height">
          <rect :width="$options.loader.width" :height="$options.loader.height" rx="4" />
        </gl-skeleton-loader>
      </div>
    </div>
  </div>
</template>
