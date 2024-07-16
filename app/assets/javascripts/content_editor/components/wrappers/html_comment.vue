<script>
import { NodeViewWrapper } from '@tiptap/vue-2';

export default {
  name: 'HTMLCommentWrapper',
  components: {
    NodeViewWrapper,
  },
  props: {
    node: {
      type: Object,
      required: true,
    },
    selected: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
};
</script>
<template>
  <node-view-wrapper
    as="div"
    class="content-editor-placeholder-container gl-rounded-base gl-border-1 gl-p-3 gl-relative !gl-cursor-pointer"
    :class="{
      'gl-border-blue-400 gl-border-solid': selected,
      'gl-border-gray-100 gl-border-dashed': !selected,
    }"
  >
    <span contenteditable="false" class="!gl-whitespace-pre-wrap gl-italic gl-text-secondary">{{
      node.attrs.description
    }}</span>
  </node-view-wrapper>
</template>
