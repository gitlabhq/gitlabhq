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
    class="gl-inline-block gl-w-8 gl-pr-2 -gl-ml-8 gl-select-none gl-text-right"
    :href="lineHref"
  >
    {{ lineNumber }}
  </a>
</template>
