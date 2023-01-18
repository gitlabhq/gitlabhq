<script>
import SafeHtml from '~/vue_shared/directives/safe_html';
import { renderGFM } from '~/behaviors/markdown/render_gfm';

export default {
  directives: {
    SafeHtml,
  },
  props: {
    note: {
      type: Object,
      required: true,
    },
  },
  mounted() {
    this.renderGFM();
  },
  methods: {
    renderGFM() {
      renderGFM(this.$refs['note-body']);
    },
  },
  safeHtmlConfig: {
    ADD_TAGS: ['use', 'gl-emoji', 'copy-code'],
  },
};
</script>

<template>
  <div ref="note-body" class="note-body">
    <div
      v-safe-html:[$options.safeHtmlConfig]="note.bodyHtml"
      class="note-text md"
      data-testid="work-item-note-body"
    ></div>
  </div>
</template>
