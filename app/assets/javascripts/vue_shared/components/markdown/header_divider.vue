<script>
export default {
  props: {
    previewMarkdown: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
};
</script>
<template>
  <div v-if="!previewMarkdown" class="md-toolbar-divider gl-display-flex gl-py-2">
    <div class="gl-border-l gl-pl-3 gl-ml-2"></div>
  </div>
</template>
