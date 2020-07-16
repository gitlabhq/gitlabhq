<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import { GlTooltipDirective } from '@gitlab/ui';
import DiffTableCell from './diff_table_cell.vue';
import {
  MATCH_LINE_TYPE,
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
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    fileHash: {
      type: String,
      required: true,
    },
    filePath: {
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
    isCommented: {
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
    ...mapGetters('diffs', ['fileLineCoverage']),
    ...mapState({
      isHighlighted(state) {
        if (this.isCommented) return true;

        const lineCode = this.line.line_code;
        return lineCode ? lineCode === state.diffs.highlightedRow : false;
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
    isMatchLine() {
      return this.line.type === MATCH_LINE_TYPE;
    },
    coverageState() {
      return this.fileLineCoverage(this.filePath, this.line.new_line);
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
    v-if="!isMatchLine"
    :id="inlineRowId"
    :class="classNameMap"
    class="line_holder"
    @mouseover="handleMouseMove"
    @mouseout="handleMouseMove"
  >
    <diff-table-cell
      :file-hash="fileHash"
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
      :line="line"
      :line-type="newLineType"
      :is-bottom="isBottom"
      :is-hover="isHover"
      :is-highlighted="isHighlighted"
      class="diff-line-num new_line qa-new-diff-line"
    />
    <td
      v-gl-tooltip.hover
      :title="coverageState.text"
      :class="[line.type, coverageState.class, { hll: isHighlighted }]"
      class="line-coverage"
    ></td>
    <td
      :class="[
        line.type,
        {
          hll: isHighlighted,
        },
      ]"
      class="line_content with-coverage"
      v-html="line.rich_text"
    ></td>
  </tr>
</template>
