<script>
import { mapActions, mapState } from 'vuex';
import DiffTableCell from './diff_table_cell.vue';
import {
  NEW_LINE_TYPE,
  OLD_LINE_TYPE,
  CONTEXT_LINE_TYPE,
  CONTEXT_LINE_CLASS_NAME,
  LINE_POSITION_LEFT,
  LINE_POSITION_RIGHT,
} from '../constants';

export default {
  components: {
    DiffTableCell,
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
    isBottom: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isHover: false,
    };
  },
  computed: {
    ...mapState({
      isHighlighted(state) {
        return this.line.line_code !== null && this.line.line_code === state.diffs.highlightedRow;
      },
    }),
    isContextLine() {
      return this.line.type === CONTEXT_LINE_TYPE;
    },
    classNameMap() {
      return [
        this.line.type,
        {
          [CONTEXT_LINE_CLASS_NAME]: this.isContextLine,
        },
      ];
    },
    inlineRowId() {
      return this.line.line_code || `${this.fileHash}_${this.line.old_line}_${this.line.new_line}`;
    },
  },
  created() {
    this.newLineType = NEW_LINE_TYPE;
    this.oldLineType = OLD_LINE_TYPE;
    this.linePositionLeft = LINE_POSITION_LEFT;
    this.linePositionRight = LINE_POSITION_RIGHT;
  },
  mounted() {
    this.scrollToLineIfNeededInline(this.line);
  },
  methods: {
    ...mapActions('diffs', ['scrollToLineIfNeededInline']),
    handleMouseMove(e) {
      // To show the comment icon on the gutter we need to know if we hover the line.
      // Current table structure doesn't allow us to do this with CSS in both of the diff view types
      this.isHover = e.type === 'mouseover';
    },
  },
};
</script>

<template>
  <tr
    :id="inlineRowId"
    :class="classNameMap"
    class="line_holder"
    @mouseover="handleMouseMove"
    @mouseout="handleMouseMove"
  >
    <diff-table-cell
      :file-hash="fileHash"
      :context-lines-path="contextLinesPath"
      :line="line"
      :line-type="oldLineType"
      :is-bottom="isBottom"
      :is-hover="isHover"
      :show-comment-button="true"
      :is-highlighted="isHighlighted"
      class="diff-line-num old_line"
    />
    <diff-table-cell
      :file-hash="fileHash"
      :context-lines-path="contextLinesPath"
      :line="line"
      :line-type="newLineType"
      :is-bottom="isBottom"
      :is-hover="isHover"
      :is-highlighted="isHighlighted"
      class="diff-line-num new_line qa-new-diff-line"
    />
    <td
      :class="[
        line.type,
        {
          hll: isHighlighted,
        },
      ]"
      class="line_content"
      v-html="line.rich_text"
    ></td>
  </tr>
</template>
