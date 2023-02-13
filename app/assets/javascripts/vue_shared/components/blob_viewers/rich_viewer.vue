<script>
import SafeHtml from '~/vue_shared/directives/safe_html';
import { handleBlobRichViewer } from '~/blob/viewer';
import MarkdownFieldView from '~/vue_shared/components/markdown/field_view.vue';
import ViewerMixin from './mixins';

export default {
  components: {
    MarkdownFieldView,
  },
  directives: {
    SafeHtml,
  },
  mixins: [ViewerMixin],
  mounted() {
    handleBlobRichViewer(this.$refs.content, this.type);
  },
  safeHtmlConfig: {
    ADD_TAGS: ['gl-emoji', 'copy-code'],
  },
};
</script>
<template>
  <markdown-field-view
    ref="content"
    v-safe-html:[$options.safeHtmlConfig]="richViewer || content"
  />
</template>
