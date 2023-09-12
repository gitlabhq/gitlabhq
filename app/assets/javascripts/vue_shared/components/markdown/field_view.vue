<script>
import { renderGFM } from '~/behaviors/markdown/render_gfm';

export default {
  props: {
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  watch: {
    isLoading() {
      this.handleGFM();
    },
  },
  mounted() {
    this.handleGFM();
  },
  methods: {
    handleGFM() {
      if (this.isLoading) return;
      renderGFM(this.$el);
    },
  },
};
</script>

<template>
  <div><slot></slot></div>
</template>
