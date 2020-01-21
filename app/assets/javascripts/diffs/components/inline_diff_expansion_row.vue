<script>
import DiffExpansionCell from './diff_expansion_cell.vue';
import { MATCH_LINE_TYPE } from '../constants';

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
    isMatchLine() {
      return this.line.type === MATCH_LINE_TYPE;
    },
  },
};
</script>

<template>
  <tr v-if="isMatchLine" class="line_expansion match">
    <diff-expansion-cell
      :file-hash="fileHash"
      :context-lines-path="contextLinesPath"
      :line="line"
      :is-top="isTop"
      :is-bottom="isBottom"
    />
  </tr>
</template>
