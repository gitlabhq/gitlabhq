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
    class="content-editor-placeholder-container gl-relative !gl-cursor-pointer gl-rounded-base gl-border-1 gl-p-3"
    :class="{
      'gl-border-solid gl-border-blue-400': selected,
      'gl-border-dashed gl-border-default': !selected,
    }"
  >
    <span contenteditable="false" class="!gl-whitespace-pre-wrap gl-italic gl-text-subtle">{{
      node.attrs.description
    }}</span>
  </node-view-wrapper>
</template>
