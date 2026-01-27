<script>
export default {
  name: 'BlameSkeletonLoader',
};
</script>

<template>
  <div
    class="gl-flex gl-items-center gl-gap-3"
    data-testid="blame-skeleton-loader"
    role="status"
    aria-busy="true"
    :aria-label="__('Loading blame information')"
  >
    <!-- Vertical bar on the left -->
    <div
      data-testid="blame-skeleton-line"
      class="gl-animate-skeleton-loader gl-h-10 gl-w-2 gl-rounded-base"
      aria-hidden="true"
    ></div>
    <!-- Avatar circle -->
    <div
      data-testid="blame-skeleton-avatar"
      class="gl-animate-skeleton-loader gl-ml-2 gl-mt-3 gl-h-[2rem] gl-w-[2rem] gl-rounded-full"
      aria-hidden="true"
    ></div>
    <!-- Text lines -->
    <div class="gl-mt-3 gl-flex gl-flex-col gl-gap-3" aria-hidden="true">
      <div
        data-testid="blame-skeleton-line"
        class="gl-animate-skeleton-loader gl-h-4 gl-w-20 gl-rounded-base"
      ></div>
      <div
        data-testid="blame-skeleton-line"
        class="gl-animate-skeleton-loader gl-h-3 gl-w-12 gl-rounded-base"
      ></div>
    </div>
  </div>
</template>
