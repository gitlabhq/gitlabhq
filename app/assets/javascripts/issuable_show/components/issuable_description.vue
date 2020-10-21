<script>
import $ from 'jquery';
import { GlSafeHtmlDirective as SafeHtml } from '@gitlab/ui';
import '~/behaviors/markdown/render_gfm';

export default {
  directives: {
    SafeHtml,
  },
  props: {
    issuable: {
      type: Object,
      required: true,
    },
  },
  mounted() {
    this.renderGFM();
  },
  methods: {
    renderGFM() {
      $(this.$refs.gfmContainer).renderGFM();
    },
  },
};
</script>

<template>
  <div class="description">
    <div ref="gfmContainer" v-safe-html="issuable.descriptionHtml" class="md"></div>
  </div>
</template>
