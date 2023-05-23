<script>
import { NodeViewWrapper } from '@tiptap/vue-2';
import { GlLabel } from '@gitlab/ui';
import { isScopedLabel } from '~/lib/utils/common_utils';

export default {
  name: 'DetailsWrapper',
  components: {
    NodeViewWrapper,
    GlLabel,
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
  computed: {
    isScopedLabel() {
      return isScopedLabel({ title: this.node.attrs.originalText });
    },
  },
};
</script>
<template>
  <node-view-wrapper as="span" :class="{ 'ProseMirror-selectednode': selected }">
    <gl-label
      size="sm"
      :scoped="isScopedLabel"
      :background-color="node.attrs.color"
      :title="node.attrs.text"
      class="gl-pointer-events-none"
    />
  </node-view-wrapper>
</template>
