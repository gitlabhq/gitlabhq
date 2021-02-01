<script>
import { GlSafeHtmlDirective as SafeHtml } from '@gitlab/ui';
import MarkdownFieldView from '~/vue_shared/components/markdown/field_view.vue';
import { handleBlobRichViewer } from '~/blob/viewer';
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
  <markdown-field-view ref="content" v-safe-html="content" />
</template>
