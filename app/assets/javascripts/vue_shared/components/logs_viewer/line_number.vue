<script>
export default {
  props: {
    lineNumber: {
      type: Number,
      required: true,
    },
    lineId: {
      type: String,
      required: true,
    },
  },
  computed: {
    lineHref() {
      return `#${this.lineId}`;
    },
  },
};
</script>
<template>
  <a
    :id="lineId"
    class="-gl-ml-9 gl-inline-block gl-w-9 gl-select-none gl-pr-2 gl-text-right"
    :href="lineHref"
  >
    {{ lineNumber }}
  </a>
</template>
