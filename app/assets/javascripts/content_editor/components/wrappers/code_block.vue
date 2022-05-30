<script>
import { NodeViewWrapper, NodeViewContent } from '@tiptap/vue-2';
import { __ } from '~/locale';
import codeBlockLanguageLoader from '../../services/code_block_language_loader';

export default {
  name: 'CodeBlock',
  components: {
    NodeViewWrapper,
    NodeViewContent,
  },
  props: {
    node: {
      type: Object,
      required: true,
    },
    updateAttributes: {
      type: Function,
      required: true,
    },
  },
  async mounted() {
    const lang = codeBlockLanguageLoader.findOrCreateLanguageBySyntax(this.node.attrs.language);
    await codeBlockLanguageLoader.loadLanguage(lang.syntax);

    this.updateAttributes({ language: this.node.attrs.language });
  },
  i18n: {
    frontmatter: __('frontmatter'),
  },
};
</script>
<template>
  <node-view-wrapper class="content-editor-code-block gl-relative code highlight" as="pre">
    <span
      v-if="node.attrs.isFrontmatter"
      data-testid="frontmatter-label"
      class="gl-absolute gl-top-0 gl-right-3"
      contenteditable="false"
      >{{ $options.i18n.frontmatter }}:{{ node.attrs.language }}</span
    >
    <node-view-content as="code" />
  </node-view-wrapper>
</template>
