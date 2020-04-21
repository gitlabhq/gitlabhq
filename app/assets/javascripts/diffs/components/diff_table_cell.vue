<script>
import { mapGetters, mapActions } from 'vuex';
import { GlIcon } from '@gitlab/ui';
import { getParameterByName, parseBoolean } from '~/lib/utils/common_utils';
import DiffGutterAvatars from './diff_gutter_avatars.vue';
import {
  MATCH_LINE_TYPE,
  CONTEXT_LINE_TYPE,
  LINE_POSITION_RIGHT,
  EMPTY_CELL_TYPE,
  OLD_LINE_TYPE,
  OLD_NO_NEW_LINE_TYPE,
  NEW_NO_NEW_LINE_TYPE,
  LINE_HOVER_CLASS_NAME,
  LINE_UNFOLD_CLASS_NAME,
} from '../constants';

export default {
  components: {
    DiffGutterAvatars,
    GlIcon,
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
    lineCode() {
      return (
        this.line.line_code ||
        (this.line.left && this.line.left.line_code) ||
        (this.line.right && this.line.right.line_code)
      );
    },
    lineHref() {
      return `#${this.line.line_code || ''}`;
    },
    shouldShowCommentButton() {
      return (
        this.isHover &&
        !this.isMatchLine &&
        !this.isContextLine &&
        !this.isMetaLine &&
        !this.hasDiscussions
      );
    },
    hasDiscussions() {
      return this.line.discussions && this.line.discussions.length > 0;
    },
    shouldShowAvatarsOnGutter() {
      if (!this.line.type && this.linePosition === LINE_POSITION_RIGHT) {
        return false;
      }
      return this.showCommentButton && this.hasDiscussions;
    },
    shouldRenderCommentButton() {
      if (this.isLoggedIn && this.showCommentButton) {
        const isDiffHead = parseBoolean(getParameterByName('diff_head'));
        return !isDiffHead || gon.features?.mergeRefHeadComments;
      }

      return false;
    },
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
  methods: {
    ...mapActions('diffs', ['showCommentForm', 'setHighlightedRow', 'toggleLineDiscussions']),
    handleCommentButton() {
      this.showCommentForm({ lineCode: this.line.line_code, fileHash: this.fileHash });
    },
  },
};
</script>

<template>
  <td ref="td" :class="classNameMap">
    <div>
      <button
        v-if="shouldRenderCommentButton"
        v-show="shouldShowCommentButton"
        ref="addDiffNoteButton"
        type="button"
        class="add-diff-note js-add-diff-note-button qa-diff-comment"
        title="Add a comment to this line"
        @click="handleCommentButton"
      >
        <gl-icon :size="12" name="comment" />
      </button>
      <a
        v-if="lineNumber"
        ref="lineNumberRef"
        :data-linenumber="lineNumber"
        :href="lineHref"
        @click="setHighlightedRow(lineCode)"
      >
      </a>
      <diff-gutter-avatars
        v-if="shouldShowAvatarsOnGutter"
        :discussions="line.discussions"
        :discussions-expanded="line.discussionsExpanded"
        @toggleLineDiscussions="
          toggleLineDiscussions({ lineCode, fileHash, expanded: !line.discussionsExpanded })
        "
      />
    </div>
  </td>
</template>
