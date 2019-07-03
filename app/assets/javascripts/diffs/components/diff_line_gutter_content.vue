<script>
import createFlash from '~/flash';
import { s__ } from '~/locale';
import { mapState, mapGetters, mapActions } from 'vuex';
import Icon from '~/vue_shared/components/icon.vue';
import DiffGutterAvatars from './diff_gutter_avatars.vue';
import { LINE_POSITION_RIGHT, UNFOLD_COUNT } from '../constants';
import * as utils from '../store/utils';

export default {
  components: {
    DiffGutterAvatars,
    Icon,
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
    lineNumber: {
      type: Number,
      required: false,
      default: 0,
    },
    linePosition: {
      type: String,
      required: false,
      default: '',
    },
    showCommentButton: {
      type: Boolean,
      required: false,
      default: false,
    },
    isBottom: {
      type: Boolean,
      required: false,
      default: false,
    },
    isMatchLine: {
      type: Boolean,
      required: false,
      default: false,
    },
    isMetaLine: {
      type: Boolean,
      required: false,
      default: false,
    },
    isContextLine: {
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
    ...mapState({
      diffViewType: state => state.diffs.diffViewType,
      diffFiles: state => state.diffs.diffFiles,
    }),
    ...mapGetters(['isLoggedIn']),
    lineCode() {
      return (
        this.line.line_code ||
        (this.line.left && this.line.line.left.line_code) ||
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
      return this.isLoggedIn && this.showCommentButton;
    },
  },
  methods: {
    ...mapActions('diffs', [
      'loadMoreLines',
      'showCommentForm',
      'setHighlightedRow',
      'toggleLineDiscussions',
      'toggleLineDiscussionWrappers',
    ]),
    handleCommentButton() {
      this.showCommentForm({ lineCode: this.line.line_code, fileHash: this.fileHash });
    },
    handleLoadMoreLines() {
      if (this.isRequesting) {
        return;
      }

      this.isRequesting = true;
      const endpoint = this.contextLinesPath;
      const oldLineNumber = this.line.meta_data.old_pos || 0;
      const newLineNumber = this.line.meta_data.new_pos || 0;
      const offset = newLineNumber - oldLineNumber;
      const bottom = this.isBottom;
      const { fileHash } = this;
      const view = this.diffViewType;
      let unfold = true;
      let lineNumber = newLineNumber - 1;
      let since = lineNumber - UNFOLD_COUNT;
      let to = lineNumber;

      if (bottom) {
        lineNumber = newLineNumber + 1;
        since = lineNumber;
        to = lineNumber + UNFOLD_COUNT;
      } else {
        const diffFile = utils.findDiffFile(this.diffFiles, this.fileHash);
        const indexForInline = utils.findIndexInInlineLines(diffFile.highlighted_diff_lines, {
          oldLineNumber,
          newLineNumber,
        });
        const prevLine = diffFile.highlighted_diff_lines[indexForInline - 2];
        const prevLineNumber = (prevLine && prevLine.new_line) || 0;

        if (since <= prevLineNumber + 1) {
          since = prevLineNumber + 1;
          unfold = false;
        }
      }

      const params = { since, to, bottom, offset, unfold, view };
      const lineNumbers = { oldLineNumber, newLineNumber };
      this.loadMoreLines({ endpoint, params, lineNumbers, fileHash })
        .then(() => {
          this.isRequesting = false;
        })
        .catch(() => {
          createFlash(s__('Diffs|Something went wrong while fetching diff lines.'));
          this.isRequesting = false;
        });
    },
  },
};
</script>

<template>
  <div>
    <span v-if="isMatchLine" class="context-cell" role="button" @click="handleLoadMoreLines"
      >...</span
    >
    <template v-else>
      <button
        v-if="shouldRenderCommentButton"
        v-show="shouldShowCommentButton"
        type="button"
        class="add-diff-note js-add-diff-note-button qa-diff-comment"
        title="Add a comment to this line"
        @click="handleCommentButton"
      >
        <icon :size="12" name="comment" />
      </button>
      <a
        v-if="lineNumber"
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
    </template>
  </div>
</template>
