<script>
import { mapGetters, mapActions } from 'vuex';
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
    isHighlighted: {
      type: Boolean,
      required: true,
      default: false,
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
    isMatchLine() {
      return this.line.type === MATCH_LINE_TYPE;
    },
    isContextLine() {
      return this.line.type === CONTEXT_LINE_TYPE;
    },
    isMetaLine() {
      const { type } = this.line;

      return (
        type === OLD_NO_NEW_LINE_TYPE || type === NEW_NO_NEW_LINE_TYPE || type === EMPTY_CELL_TYPE
      );
    },
    classNameMap() {
      const { type } = this.line;

      return [
        type,
        {
          hll: this.isHighlighted,
          [LINE_UNFOLD_CLASS_NAME]: this.isMatchLine,
          [LINE_HOVER_CLASS_NAME]:
            this.isLoggedIn &&
            this.isHover &&
            !this.isMatchLine &&
            !this.isContextLine &&
            !this.isMetaLine,
        },
      ];
    },
    lineNumber() {
      return this.lineType === OLD_LINE_TYPE ? this.line.old_line : this.line.new_line;
    },
  },
  methods: mapActions('diffs', ['setHighlightedRow']),
};
</script>

<template>
  <td :class="classNameMap">
    <diff-line-gutter-content
      :line="line"
      :file-hash="fileHash"
      :context-lines-path="contextLinesPath"
      :line-position="linePosition"
      :line-number="lineNumber"
      :show-comment-button="showCommentButton"
      :is-hover="isHover"
      :is-bottom="isBottom"
      :is-match-line="isMatchLine"
      :is-context-line="isContentLine"
      :is-meta-line="isMetaLine"
    />
  </td>
</template>
