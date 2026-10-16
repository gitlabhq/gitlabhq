<script>
export default {
  name: 'ActivitySkeletonLoader',
  props: {
    count: {
      type: Number,
      required: false,
      default: 3,
    },
  },
};
</script>

<template>
  <div class="gl-flex gl-flex-col gl-gap-6" data-testid="activities-skeleton" aria-hidden="true">
    <div v-for="n in count" :key="n" class="gl-flex gl-items-center gl-gap-3">
      <div class="gl-animate-skeleton-loader gl-h-6 gl-w-6 gl-shrink-0 gl-rounded-full"></div>
      <div class="gl-flex gl-grow gl-flex-col gl-gap-2">
        <div
          class="gl-animate-skeleton-loader gl-h-4 gl-w-1/2 !gl-max-w-none gl-rounded-base"
        ></div>
        <div class="gl-animate-skeleton-loader gl-h-3 gl-w-1/8 gl-rounded-base"></div>
      </div>
      <div class="gl-animate-skeleton-loader gl-h-3 gl-w-12 gl-shrink-0 gl-rounded-base"></div>
    </div>
  </div>
</template>
