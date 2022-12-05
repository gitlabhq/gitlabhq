<script>
export default {
  props: {
    jobName: {
      type: String,
      required: true,
    },
  },
};
</script>
<template>
  <div
    class="gl-w-13 gl-h-6 gl-font-sm gl-bg-white gl-inset-border-1-blue-500 gl-text-center gl-text-truncate gl-rounded-pill gl-px-4 gl-py-2 gl-relative gl-z-index-1 gl-transition-duration-slow gl-transition-timing-function-ease"
  >
    {{ jobName }}
  </div>
</template>
