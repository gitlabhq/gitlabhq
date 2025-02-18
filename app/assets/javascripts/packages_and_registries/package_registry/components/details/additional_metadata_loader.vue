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
  <div class="gl-rounded-base gl-bg-strong gl-shadow-inner-1-gray-100">
    <div
      v-for="index in $options.loader.repeat"
      :key="index"
      class="gl-flex gl-items-center gl-border-b-1 gl-border-default gl-p-4"
    >
      <div class="md:gl-max-w-3/10">
        <gl-skeleton-loader :width="$options.loader.width" :height="$options.loader.height">
          <rect :width="$options.loader.width" :height="$options.loader.height" rx="4" />
        </gl-skeleton-loader>
      </div>
    </div>
  </div>
</template>
