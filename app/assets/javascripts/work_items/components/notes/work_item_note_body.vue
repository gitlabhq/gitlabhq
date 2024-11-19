<script>
import SafeHtml from '~/vue_shared/directives/safe_html';
import { renderGFM } from '~/behaviors/markdown/render_gfm';

export default {
  name: 'WorkItemNoteBody',
  directives: {
    SafeHtml,
  },
  props: {
    note: {
      type: Object,
      required: true,
    },
    hasReplies: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  watch: {
    'note.bodyHtml': {
      immediate: true,
      async handler(newVal, oldVal) {
        if (newVal === oldVal) {
          return;
        }
        await this.$nextTick();
        this.renderGFM();
      },
    },
  },
  methods: {
    renderGFM() {
      renderGFM(this.$refs['note-body']);
      gl?.lazyLoader?.searchLazyImages();
    },
  },
  safeHtmlConfig: {
    ADD_TAGS: ['use', 'gl-emoji', 'copy-code'],
  },
};
</script>

<template>
  <div ref="note-body">
    <div
      v-safe-html:[$options.safeHtmlConfig]="note.bodyHtml"
      class="note-text md"
      data-testid="work-item-note-body"
    ></div>
  </div>
</template>
