<script>
import SafeHtml from '~/vue_shared/directives/safe_html';
import { handleBlobRichViewer } from '~/blob/viewer';
import MarkdownFieldView from '~/vue_shared/components/markdown/field_view.vue';
import { handleLocationHash } from '~/lib/utils/common_utils';
import { sanitize, defaultConfig } from '~/lib/dompurify';
import ViewerMixin from './mixins';
import {
  MARKUP_FILE_TYPE,
  MARKUP_CONTENT_SELECTOR,
  ELEMENTS_PER_CHUNK,
  CONTENT_LOADED_EVENT,
} from './constants';

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
      initialContent: null,
      remainingContent: [],
    };
  },
  computed: {
    rawContent() {
      return this.initialContent || this.richViewer || this.content;
    },
    isMarkup() {
      return this.type === MARKUP_FILE_TYPE;
    },
  },
  created() {
    this.optimizeMarkupRendering();
  },
  mounted() {
    this.renderRemainingMarkup();
    handleBlobRichViewer(this.$refs.content, this.type);
  },
  methods: {
    optimizeMarkupRendering() {
      /**
       * If content is markup we optimize rendering by splitting it into two parts:
       * - initialContent (top section of the file - is rendered right away)
       * - remainingContent (remaining content - is rendered over a longer time period)
       *
       * This is done so that the browser doesn't render the whole file at once (improves TBT)
       */

      if (!this.isMarkup) return;

      const tmpWrapper = document.createElement('div');
      tmpWrapper.innerHTML = sanitize(this.rawContent, this.$options.safeHtmlConfig);

      const fileContent = tmpWrapper.querySelector(MARKUP_CONTENT_SELECTOR);
      if (!fileContent) return;

      const initialContent = [...fileContent.childNodes].slice(0, ELEMENTS_PER_CHUNK);
      this.remainingContent = [...fileContent.childNodes].slice(ELEMENTS_PER_CHUNK);

      fileContent.innerHTML = '';
      fileContent.append(...initialContent);
      this.initialContent = tmpWrapper.outerHTML;
    },
    renderRemainingMarkup() {
      /**
       * Rendering large Markdown files can block the main thread due to the amount of HTML being parsed.
       * The optimization below ensures that content is rendered over a longer time period instead of all at once.
       * More details here: https://gitlab.com/gitlab-org/gitlab/-/issues/331448
       * */

      if (!this.isMarkup || !this.remainingContent.length) {
        this.onContentLoaded();
        return;
      }

      const fileContent = this.$refs.content.$el.querySelector(MARKUP_CONTENT_SELECTOR);

      for (let i = 0; i < this.remainingContent.length; i += ELEMENTS_PER_CHUNK) {
        const nextChunkEnd = i + ELEMENTS_PER_CHUNK;
        const content = this.remainingContent.slice(i, nextChunkEnd);
        setTimeout(() => {
          fileContent.append(...content);
          if (nextChunkEnd < this.remainingContent.length) return;
          this.onContentLoaded();
        }, i);
      }
    },
    onContentLoaded() {
      this.$emit(CONTENT_LOADED_EVENT);
      handleLocationHash();
      this.isLoading = false;
    },
  },
  safeHtmlConfig: {
    ...defaultConfig,
    FORBID_ATTR: [...defaultConfig.FORBID_ATTR, 'style', 'data-lines-path'],
  },
};
</script>
<template>
  <markdown-field-view
    ref="content"
    v-safe-html:[$options.safeHtmlConfig]="rawContent"
    :is-loading="isLoading"
  />
</template>
