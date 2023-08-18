<!-- eslint-disable vue/multi-word-component-names -->
<script>
export default {
  props: {
    page: {
      type: Object,
      required: true,
    },
    number: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      scale: 4,
      rendering: false,
    };
  },
  computed: {
    viewport() {
      return this.page.getViewport({ scale: this.scale });
    },
    context() {
      return this.$refs.canvas.getContext('2d');
    },
    renderContext() {
      return {
        canvasContext: this.context,
        viewport: this.viewport,
      };
    },
  },
  mounted() {
    this.$refs.canvas.height = this.viewport.height;
    this.$refs.canvas.width = this.viewport.width;
    this.rendering = true;
    this.page
      .render(this.renderContext)
      .promise.then(() => {
        this.rendering = false;
      })
      .catch((error) => {
        this.$emit('pdflaberror', error);
      });
  },
};
</script>

<template>
  <canvas ref="canvas" :data-page="number" class="pdf-page"> </canvas>
</template>

<style>
.pdf-page {
  margin: 8px auto 0;
  border-top: 1px #ddd solid;
  border-bottom: 1px #ddd solid;
  width: 100%;
}

.pdf-page:first-child {
  margin-top: 0;
  border-top: 0;
}

.pdf-page:last-child {
  margin-bottom: 0;
  border-bottom: 0;
}
</style>
