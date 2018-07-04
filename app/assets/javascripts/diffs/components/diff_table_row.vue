<script>
import $ from 'jquery';
import { mapGetters } from 'vuex';
import DiffTableCell from './diff_table_cell.vue';
import {
  NEW_LINE_TYPE,
  OLD_LINE_TYPE,
  CONTEXT_LINE_TYPE,
  CONTEXT_LINE_CLASS_NAME,
  OLD_NO_NEW_LINE_TYPE,
  PARALLEL_DIFF_VIEW_TYPE,
  NEW_NO_NEW_LINE_TYPE,
  LINE_POSITION_LEFT,
  LINE_POSITION_RIGHT,
} from '../constants';

export default {
  components: {
    DiffTableCell,
  },
  props: {
    diffFile: {
      type: Object,
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
      isLeftHover: false,
      isRightHover: false,
    };
  },
  computed: {
    ...mapGetters(['isInlineView', 'isParallelView']),
    isContextLine() {
      return this.line.left
        ? this.line.left.type === CONTEXT_LINE_TYPE
        : this.line.type === CONTEXT_LINE_TYPE;
    },
    classNameMap() {
      return {
        [this.line.type]: this.line.type,
        [CONTEXT_LINE_CLASS_NAME]: this.isContextLine,
        [PARALLEL_DIFF_VIEW_TYPE]: this.isParallelView,
      };
    },
    inlineRowId() {
      const { lineCode, oldLine, newLine } = this.line;

      return lineCode || `${this.diffFile.fileHash}_${oldLine}_${newLine}`;
    },
    parallelViewLeftLineType() {
      if (this.line.right.type === NEW_NO_NEW_LINE_TYPE) {
        return OLD_NO_NEW_LINE_TYPE;
      }

      return this.line.left.type;
    },
  },
  created() {
    this.newLineType = NEW_LINE_TYPE;
    this.oldLineType = OLD_LINE_TYPE;
    this.linePositionLeft = LINE_POSITION_LEFT;
    this.linePositionRight = LINE_POSITION_RIGHT;
  },
  methods: {
    handleMouseMove(e) {
      const isHover = e.type === 'mouseover';

      if (this.isInlineView) {
        this.isHover = isHover;
      } else {
        const hoveringCell = e.target.closest('td');
        const allCellsInHoveringRow = Array.from(e.currentTarget.children);
        const hoverIndex = allCellsInHoveringRow.indexOf(hoveringCell);

        if (hoverIndex >= 2) {
          this.isRightHover = isHover;
        } else {
          this.isLeftHover = isHover;
        }
      }
    },
    // Prevent text selecting on both sides of parallel diff view
    // Backport of the same code from legacy diff notes.
    handleParallelLineMouseDown(e) {
      const line = $(e.currentTarget);
      const table = line.closest('table');

      table.removeClass('left-side-selected right-side-selected');
      const [lineClass] = ['left-side', 'right-side'].filter(name => line.hasClass(name));

      if (lineClass) {
        table.addClass(`${lineClass}-selected`);
      }
    },
  },
};
</script>

<template>
  <tr
    v-if="isInlineView"
    :id="inlineRowId"
    :class="classNameMap"
    class="line_holder"
    @mouseover="handleMouseMove"
    @mouseout="handleMouseMove"
  >
    <diff-table-cell
      :diff-file="diffFile"
      :line="line"
      :line-type="oldLineType"
      :is-bottom="isBottom"
      :is-hover="isHover"
      :show-comment-button="true"
      class="diff-line-num old_line"
    />
    <diff-table-cell
      :diff-file="diffFile"
      :line="line"
      :line-type="newLineType"
      :is-bottom="isBottom"
      :is-hover="isHover"
      class="diff-line-num new_line"
    />
    <diff-table-cell
      :class="line.type"
      :diff-file="diffFile"
      :line="line"
      :is-content-line="true"
    />
  </tr>

  <tr
    v-else
    :class="classNameMap"
    class="line_holder"
    @mouseover="handleMouseMove"
    @mouseout="handleMouseMove"
  >
    <diff-table-cell
      :diff-file="diffFile"
      :line="line"
      :line-type="oldLineType"
      :line-position="linePositionLeft"
      :is-bottom="isBottom"
      :is-hover="isLeftHover"
      :show-comment-button="true"
      class="diff-line-num old_line"
    />
    <diff-table-cell
      :id="line.left.lineCode"
      :diff-file="diffFile"
      :line="line"
      :is-content-line="true"
      :line-position="linePositionLeft"
      :line-type="parallelViewLeftLineType"
      class="line_content parallel left-side"
      @mousedown.native="handleParallelLineMouseDown"
    />
    <diff-table-cell
      :diff-file="diffFile"
      :line="line"
      :line-type="newLineType"
      :line-position="linePositionRight"
      :is-bottom="isBottom"
      :is-hover="isRightHover"
      :show-comment-button="true"
      class="diff-line-num new_line"
    />
    <diff-table-cell
      :id="line.right.lineCode"
      :diff-file="diffFile"
      :line="line"
      :is-content-line="true"
      :line-position="linePositionRight"
      :line-type="line.right.type"
      class="line_content parallel right-side"
      @mousedown.native="handleParallelLineMouseDown"
    />
  </tr>
</template>
