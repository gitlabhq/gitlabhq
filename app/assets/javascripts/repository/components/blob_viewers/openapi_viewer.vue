<script>
import renderOpenApi from '~/blob/openapi';

export default {
  props: {
    blob: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      url: this.blob.rawPath,
    };
  },
  mounted() {
    renderOpenApi(this.$refs.viewer);
  },
};
</script>

<template>
  <div ref="viewer" class="file-content" :data-endpoint="url" data-testid="openapi"></div>
</template>
