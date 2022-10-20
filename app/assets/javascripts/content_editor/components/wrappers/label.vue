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
  },
  computed: {
    isScopedLabel() {
      return isScopedLabel({ title: this.node.attrs.originalText });
    },
  },
};
</script>
<template>
  <node-view-wrapper class="gl-display-inline-block">
    <gl-label
      size="sm"
      :scoped="isScopedLabel"
      :background-color="node.attrs.color"
      :title="node.attrs.text"
    />
  </node-view-wrapper>
</template>
