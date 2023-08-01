<script>
import SafeHtml from '~/vue_shared/directives/safe_html';
import { handleBlobRichViewer } from '~/blob/viewer';
import MarkdownFieldView from '~/vue_shared/components/markdown/field_view.vue';
import { handleLocationHash } from '~/lib/utils/common_utils';
import ViewerMixin from './mixins';

export default {
  components: {
    MarkdownFieldView,
  },
  directives: {
    SafeHtml,
  },
  mixins: [ViewerMixin],
  data() {
    return {
      isLoading: true,
    };
  },
  mounted() {
    window.requestIdleCallback(async () => {
      /**
       * Rendering Markdown usually takes long due to the amount of HTML being parsed.
       * This ensures that content is loaded only when the browser goes into idle.
       * More details here: https://gitlab.com/gitlab-org/gitlab/-/issues/331448
       * */
      this.isLoading = false;
      await this.$nextTick();
      handleBlobRichViewer(this.$refs.content, this.type);
      handleLocationHash();
      this.$emit('richContentLoaded');
    });
  },
  safeHtmlConfig: {
    ADD_TAGS: ['gl-emoji', 'copy-code'],
  },
};
</script>
<template>
  <markdown-field-view
    v-if="!isLoading"
    ref="content"
    v-safe-html:[$options.safeHtmlConfig]="richViewer || content"
  />
</template>
