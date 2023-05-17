<script>
import { NodeViewWrapper, NodeViewContent } from '@tiptap/vue-2';

export default {
  name: 'FootnoteDefinitionWrapper',
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
};
</script>
<template>
  <node-view-wrapper class="gl-display-flex gl-font-sm" as="div">
    <span
      data-testid="footnote-label"
      contenteditable="false"
      class="gl-display-inline-flex gl-mr-2"
      dir="auto"
      >{{ node.attrs.label }}:</span
    >
    <node-view-content />
  </node-view-wrapper>
</template>
