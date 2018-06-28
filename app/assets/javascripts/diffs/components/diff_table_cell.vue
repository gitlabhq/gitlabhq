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
    diffFile: {
      type: Object,
      required: true,
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
    ...mapGetters(['isLoggedIn', 'isInlineView']),
    normalizedLine() {
      if (this.isInlineView) {
        return this.line;
      }

      return this.lineType === OLD_LINE_TYPE ? this.line.left : this.line.right;
    },
    isMatchLine() {
      return this.normalizedLine.type === MATCH_LINE_TYPE;
    },
    isContextLine() {
      return this.normalizedLine.type === CONTEXT_LINE_TYPE;
    },
    isMetaLine() {
      return (
        this.normalizedLine.type === OLD_NO_NEW_LINE_TYPE ||
        this.normalizedLine.type === NEW_NO_NEW_LINE_TYPE ||
        this.normalizedLine.type === EMPTY_CELL_TYPE
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
    v-if="isContentLine"
    :class="lineType"
    class="line_content"
    v-html="normalizedLine.richText"
  >
  </td>
  <td
    v-else
    :class="classNameMap"
  >
    <diff-line-gutter-content
      :file-hash="diffFile.fileHash"
      :line-type="normalizedLine.type"
      :line-code="normalizedLine.lineCode"
      :line-position="linePosition"
      :line-number="lineNumber"
      :meta-data="normalizedLine.metaData"
      :show-comment-button="showCommentButton"
      :context-lines-path="diffFile.contextLinesPath"
      :is-bottom="isBottom"
      :is-match-line="isMatchLine"
      :is-context-line="isContentLine"
      :is-meta-line="isMetaLine"
    />
  </td>
</template>
