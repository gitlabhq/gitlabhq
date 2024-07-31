<script>
/*
This component is designed to render the markdown, which is **not** the GitLab Flavored Markdown.

It renders the code snippets the same way GitLab Flavored Markdown code snippets are rendered
respecting the user's preferred color scheme and featuring a copy-code button.

This component can be used to render client-side markdown that doesn't have GitLab-specific markdown elements such as issue links.
*/
import { marked } from 'marked';
import CodeBlockHighlighted from '~/vue_shared/components/code_block_highlighted.vue';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { sanitize } from '~/lib/dompurify';
import { markdownConfig } from '~/lib/utils/text_utility';
import { __ } from '~/locale';
import ModalCopyButton from '~/vue_shared/components/modal_copy_button.vue';

export default {
  components: {
    CodeBlockHighlighted,
    ModalCopyButton,
  },
  directives: {
    SafeHtml,
  },
  props: {
    markdown: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      hoverMap: {},
    };
  },
  computed: {
    markdownBlocks() {
      // we use lexer https://marked.js.org/using_pro#lexer
      // to get an array of tokens that marked npm module uses.
      // We will use these tokens to override rendering of some of them
      // with our vue components
      const tokens = marked.lexer(this.markdown);

      // since we only want to differentiate between code and non-code blocks
      // we want non-code blocks merged together so that the markdown parser could render
      // them according to the markdown rules.
      // This way we introduce minimum extra wrapper mark-up
      const flattenedTokens = [];

      for (const token of tokens) {
        const lastFlattenedToken = flattenedTokens[flattenedTokens.length - 1];
        if (token.type === 'code') {
          flattenedTokens.push(token);
        } else if (lastFlattenedToken?.type === 'markdown') {
          lastFlattenedToken.raw += token.raw;
        } else {
          flattenedTokens.push({ type: 'markdown', raw: token.raw });
        }
      }

      return flattenedTokens;
    },
  },
  methods: {
    getSafeHtml(markdown) {
      return sanitize(marked.parse(markdown), markdownConfig);
    },
    setHoverOn(key) {
      this.hoverMap = { ...this.hoverMap, [key]: true };
    },
    setHoverOff(key) {
      this.hoverMap = { ...this.hoverMap, [key]: false };
    },
    isLastElement(index) {
      return index === this.markdownBlocks.length - 1;
    },
  },
  safeHtmlConfig: {
    ADD_TAGS: ['use', 'gl-emoji', 'copy-code'],
  },
  i18n: {
    copyCodeTitle: __('Copy code'),
  },
  fallbackLanguage: 'text',
};
</script>
<template>
  <div>
    <template v-for="(block, index) in markdownBlocks">
      <div
        v-if="block.type === 'code'"
        :key="`code-${index}`"
        :class="{ 'gl-relative': true, 'gl-mb-4': !isLastElement(index) }"
        data-testid="code-block-wrapper"
        @mouseenter="setHoverOn(`code-${index}`)"
        @mouseleave="setHoverOff(`code-${index}`)"
      >
        <modal-copy-button
          v-if="hoverMap[`code-${index}`]"
          :title="$options.i18n.copyCodeTitle"
          :text="block.text"
          class="gl-absolute gl-right-3 gl-top-3 gl-z-1 gl-duration-medium"
        />
        <code-block-highlighted
          class="gl-border gl-mb-0 gl-overflow-y-auto !gl-rounded-none gl-p-4"
          :language="block.lang || $options.fallbackLanguage"
          :code="block.text"
        />
      </div>
      <div
        v-else
        :key="`text-${index}`"
        v-safe-html:[$options.safeHtmlConfig]="getSafeHtml(block.raw)"
        :class="{ 'non-gfm-markdown-block': true, 'gl-mb-4': !isLastElement(index) }"
        data-testid="non-code-markdown"
      ></div>
    </template>
  </div>
</template>

<style lang="scss">
/* This is to override a margin caused by bootstrap */
.non-gfm-markdown-block {
  p {
    margin-bottom: 0;
  }
}
</style>
