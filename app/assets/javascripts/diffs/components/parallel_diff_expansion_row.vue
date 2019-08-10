<script>
import { MATCH_LINE_TYPE } from '../constants';
import DiffExpansionCell from './diff_expansion_cell.vue';

export default {
  components: {
    DiffExpansionCell,
  },
  props: {
    fileHash: {
      type: String,
      required: true,
    },
    contextLinesPath: {
      type: String,
      required: true,
    },
    line: {
      type: Object,
      required: true,
    },
    isTop: {
      type: Boolean,
      required: false,
      default: false,
    },
    isBottom: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    isMatchLineLeft() {
      return this.line.left && this.line.left.type === MATCH_LINE_TYPE;
    },
    isMatchLineRight() {
      return this.line.right && this.line.right.type === MATCH_LINE_TYPE;
    },
  },
};
</script>
<template>
  <tr class="line_expansion match">
    <template v-if="isMatchLineLeft || isMatchLineRight">
      <diff-expansion-cell
        :file-hash="fileHash"
        :context-lines-path="contextLinesPath"
        :line="line.left"
        :is-top="isTop"
        :is-bottom="isBottom"
        :colspan="4"
      />
    </template>
  </tr>
</template>
