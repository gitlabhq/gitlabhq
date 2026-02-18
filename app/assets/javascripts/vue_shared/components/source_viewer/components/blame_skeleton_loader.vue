<script>
export default {
  name: 'BlameSkeletonLoader',
  loaderInterval: 2, // Show a loader every 2nd line
  props: {
    totalLines: {
      type: Number,
      required: true,
    },
    startLine: {
      type: Number,
      required: false,
      default: 0,
    },
  },
  methods: {
    showLoader(line) {
      // Show a loader every nth line, offset by startLine for even spacing
      const lineOffset = this.startLine + line - 1;
      return lineOffset % this.$options.loaderInterval === 0;
    },
  },
};
</script>

<template>
  <div
    data-testid="blame-skeleton-loader"
    role="status"
    aria-busy="true"
    :aria-label="__('Loading blame information')"
  >
    <div
      v-for="line in totalLines"
      :key="line"
      style="height: var(--blame-line-height)"
      class="gl-flex gl-items-center gl-gap-3"
      aria-hidden="true"
    >
      <template v-if="showLoader(line)">
        <!-- Vertical bar on the left -->
        <div
          data-testid="blame-skeleton-bar"
          class="gl-animate-skeleton-loader gl-h-full gl-w-1 gl-shrink-0 gl-rounded-base"
          aria-hidden="true"
        ></div>

        <!-- Date -->
        <div
          data-testid="blame-skeleton-date"
          class="gl-animate-skeleton-loader gl-h-3 gl-w-12 gl-shrink-0 gl-rounded-base"
          aria-hidden="true"
        ></div>

        <!-- Avatar circle -->
        <div
          data-testid="blame-skeleton-avatar"
          class="gl-animate-skeleton-loader gl-h-4 gl-w-4 gl-shrink-0 gl-rounded-full"
          aria-hidden="true"
        ></div>

        <!-- Commit title -->
        <div class="gl-min-w-0 gl-flex-1">
          <div
            data-testid="blame-skeleton-title"
            class="gl-animate-skeleton-loader gl-h-3 gl-w-34 gl-rounded-base"
            aria-hidden="true"
          ></div>
        </div>
      </template>
    </div>
  </div>
</template>
