<script>
import $ from 'jquery';
import '~/behaviors/markdown/render_gfm';

export default {
  mounted() {
    this.renderGFM();
  },
  methods: {
    renderGFM() {
      $(this.$el).renderGFM();
    },
  },
};
</script>

<template>
  <div><slot></slot></div>
</template>
