<script>
import { renderGFM } from '~/behaviors/markdown/render_gfm';

export default {
  mounted() {
    renderGFM(this.$el);
  },
};
</script>

<template>
  <div><slot></slot></div>
</template>
