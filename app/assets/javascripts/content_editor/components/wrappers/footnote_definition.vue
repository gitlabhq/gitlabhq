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
  <node-view-wrapper class="gl-flex gl-text-sm" as="div">
    <span
      :contenteditable="false"
      data-testid="footnote-label"
      class="gl-mr-2 gl-inline-flex"
      dir="auto"
      >{{ node.attrs.label }}:</span
    >
    <node-view-content />
  </node-view-wrapper>
</template>
