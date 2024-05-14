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
      return isScopedLabel({ title: this.node.attrs.originalText || this.node.attrs.text });
    },
  },
  fallbackLabelBackgroundColor: '#ccc',
};
</script>
<template>
  <node-view-wrapper as="span" :class="{ 'ProseMirror-selectednode': selected }">
    <gl-label
      :scoped="isScopedLabel"
      :background-color="node.attrs.color || $options.fallbackLabelBackgroundColor"
      :title="node.attrs.text"
      class="gl-pointer-events-none"
    />
  </node-view-wrapper>
</template>
