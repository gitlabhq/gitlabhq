<script>
import { NodeViewWrapper, NodeViewContent } from '@tiptap/vue-2';
import { __ } from '~/locale';

export default {
  name: 'FrontMatter',
  components: {
    NodeViewWrapper,
    NodeViewContent,
  },
  props: {
    node: {
      type: Object,
      required: true,
    },
  },
  i18n: {
    frontmatter: __('frontmatter'),
  },
};
</script>
<template>
  <node-view-wrapper class="content-editor-code-block gl-relative code highlight" as="pre">
    <span
      data-testid="frontmatter-label"
      class="gl-absolute gl-top-0 gl-right-3"
      contenteditable="false"
      >{{ $options.i18n.frontmatter }}:{{ node.attrs.language }}</span
    >
    <node-view-content as="code" />
  </node-view-wrapper>
</template>
