<script>
import MarkdownFieldView from '~/vue_shared/components/markdown/field_view.vue';
import ViewerMixin from './mixins';
import { handleBlobRichViewer } from '~/blob/viewer';

export default {
  components: {
    MarkdownFieldView,
  },
  mixins: [ViewerMixin],
  mounted() {
    handleBlobRichViewer(this.$refs.content, this.type);
  },
};
</script>
<template>
  <markdown-field-view ref="content" v-html="content" />
</template>
