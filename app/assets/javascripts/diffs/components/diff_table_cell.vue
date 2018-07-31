<script>
import { mapGetters } from 'vuex';
import DiffLineGutterContent from './diff_line_gutter_content.vue';
import {
  MATCH_LINE_TYPE,
  CONTEXT_LINE_TYPE,
  EMPTY_CELL_TYPE,
  OLD_LINE_TYPE,
  OLD_NO_NEW_LINE_TYPE,
  NEW_NO_NEW_LINE_TYPE,
  LINE_HOVER_CLASS_NAME,
  LINE_UNFOLD_CLASS_NAME,
  INLINE_DIFF_VIEW_TYPE,
  LINE_POSITION_LEFT,
  LINE_POSITION_RIGHT,
} from '../constants';

export default {
  components: {
    DiffLineGutterContent,
  },
  props: {
    line: {
      type: Object,
      required: true,
    },
    fileHash: {
      type: String,
      required: true,
    },
    contextLinesPath: {
      type: String,
      required: true,
    },
    diffViewType: {
      type: String,
      required: false,
      default: INLINE_DIFF_VIEW_TYPE,
    },
    showCommentButton: {
      type: Boolean,
      required: false,
      default: false,
    },
    linePosition: {
      type: String,
      required: false,
      default: '',
    },
    lineType: {
      type: String,
      required: false,
      default: '',
    },
    isContentLine: {
      type: Boolean,
      required: false,
      default: false,
    },
    isBottom: {
      type: Boolean,
      required: false,
      default: false,
    },
    isHover: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    ...mapGetters(['isLoggedIn']),
    normalizedLine() {
      let normalizedLine;

      if (this.diffViewType === INLINE_DIFF_VIEW_TYPE) {
        normalizedLine = this.line;
      } else if (this.linePosition === LINE_POSITION_LEFT) {
        normalizedLine = this.line.left;
      } else if (this.linePosition === LINE_POSITION_RIGHT) {
        normalizedLine = this.line.right;
      }

      return normalizedLine;
    },
    isMatchLine() {
      return this.normalizedLine.type === MATCH_LINE_TYPE;
    },
    isContextLine() {
      return this.normalizedLine.type === CONTEXT_LINE_TYPE;
    },
    isMetaLine() {
      const { type } = this.normalizedLine;

      return (
        type === OLD_NO_NEW_LINE_TYPE || type === NEW_NO_NEW_LINE_TYPE || type === EMPTY_CELL_TYPE
      );
    },
    classNameMap() {
      const { type } = this.normalizedLine;

      return {
        [type]: type,
        [LINE_UNFOLD_CLASS_NAME]: this.isMatchLine,
        [LINE_HOVER_CLASS_NAME]:
          this.isLoggedIn &&
          this.isHover &&
          !this.isMatchLine &&
          !this.isContextLine &&
          !this.isMetaLine,
      };
    },
    lineNumber() {
      const { lineType, normalizedLine } = this;

      return lineType === OLD_LINE_TYPE ? normalizedLine.oldLine : normalizedLine.newLine;
    },
  },
};
</script>

<template>
  <td
    :class="classNameMap"
  >
    <diff-line-gutter-content
      :file-hash="fileHash"
      :context-lines-path="contextLinesPath"
      :line-type="normalizedLine.type"
      :line-code="normalizedLine.lineCode"
      :line-position="linePosition"
      :line-number="lineNumber"
      :meta-data="normalizedLine.metaData"
      :show-comment-button="showCommentButton"
      :is-bottom="isBottom"
      :is-match-line="isMatchLine"
      :is-context-line="isContentLine"
      :is-meta-line="isMetaLine"
    />
  </td>
</template>
