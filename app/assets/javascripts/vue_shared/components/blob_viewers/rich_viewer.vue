<script>
import { GlSafeHtmlDirective as SafeHtml } from '@gitlab/ui';
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
};
</script>
<template>
  <markdown-field-view ref="content" v-safe-html="richViewer || content" />
</template>
