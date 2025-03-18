<script>
import { NodeViewWrapper, NodeViewContent } from '@tiptap/vue-2';

const TABLE_CELL_HEADER = 'th';
const TABLE_CELL_BODY = 'td';

export default {
  name: 'TableCellBaseWrapper',
  components: {
    NodeViewWrapper,
    NodeViewContent,
  },
  props: {
    cellType: {
      type: String,
      validator: (type) => [TABLE_CELL_HEADER, TABLE_CELL_BODY].includes(type),
      required: true,
    },
    node: {
      type: Object,
      required: true,
    },
  },
};
</script>
<template>
  <node-view-wrapper
    :as="cellType"
    :rowspan="node.attrs.rowspan || 1"
    :colspan="node.attrs.colspan || 1"
    :align="node.attrs.align || 'left'"
    dir="auto"
    class="gl-relative !gl-m-0 !gl-p-0"
  >
    <node-view-content
      as="div"
      class="gl-min-w-10 gl-p-5"
      :style="{ 'text-align': node.attrs.align || 'left' }"
    />
  </node-view-wrapper>
</template>
