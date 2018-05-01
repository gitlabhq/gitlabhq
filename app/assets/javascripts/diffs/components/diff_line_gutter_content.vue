<script>
import createFlash from '~/flash';
import { s__ } from '~/locale';
import { mapState, mapGetters, mapActions } from 'vuex';
import Icon from '~/vue_shared/components/icon.vue';
import DiffGutterAvatars from './diff_gutter_avatars.vue';
import {
  MATCH_LINE_TYPE,
  CONTEXT_LINE_TYPE,
  OLD_NO_NEW_LINE_TYPE,
  NEW_NO_NEW_LINE_TYPE,
  LINE_POSITION_RIGHT,
  UNFOLD_COUNT,
} from '../constants';
import * as utils from '../store/utils';

export default {
  props: {
    fileHash: {
      type: String,
      required: true,
    },
    contextLinesPath: {
      type: String,
      required: true,
    },
    lineType: {
      type: String,
      required: false,
      default: '',
    },
    lineNumber: {
      type: Number,
      required: false,
      default: 0,
    },
    lineCode: {
      type: String,
      required: false,
      default: '',
    },
    linePosition: {
      type: String,
      required: false,
      default: '',
    },
    metaData: {
      type: Object,
      required: false,
      default: () => ({}),
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
  },
  components: {
    DiffGutterAvatars,
    Icon,
  },
  computed: {
    ...mapState({
      diffViewType: state => state.diffs.diffViewType,
      diffFiles: state => state.diffs.diffFiles,
    }),
    ...mapGetters(['isLoggedIn', 'discussionsByLineCode']),
    isMatchLine() {
      return this.lineType === MATCH_LINE_TYPE;
    },
    isContextLine() {
      return this.lineType === CONTEXT_LINE_TYPE;
    },
    isMetaLine() {
      return this.lineType === OLD_NO_NEW_LINE_TYPE || this.lineType === NEW_NO_NEW_LINE_TYPE;
    },
    lineHref() {
      return this.lineCode ? `#${this.lineCode}` : '#';
    },
    shouldShowCommentButton() {
      return (
        this.isLoggedIn &&
        this.showCommentButton &&
        !this.isMatchLine &&
        !this.isContextLine &&
        !this.hasDiscussions &&
        !this.isMetaLine
      );
    },
    discussions() {
      return this.discussionsByLineCode[this.lineCode] || [];
    },
    hasDiscussions() {
      return this.discussions.length > 0;
    },
    shouldShowAvatarsOnGutter() {
      let render = this.hasDiscussions && this.showCommentButton;

      if (!this.lineType && this.linePosition === LINE_POSITION_RIGHT) {
        render = false;
      }

      return render;
    },
  },
  methods: {
    ...mapActions(['loadMoreLines']),
    handleCommentButton() {
      this.$emit('showCommentForm', { lineCode: this.lineCode });
    },
    handleLoadMoreLines() {
      if (this.isRequesting) {
        return;
      }

      this.isRequesting = true;
      const endpoint = this.contextLinesPath;
      const oldLineNumber = this.metaData.oldPos || 0;
      const newLineNumber = this.metaData.newPos || 0;
      const offset = newLineNumber - oldLineNumber;
      const bottom = this.isBottom;
      const fileHash = this.fileHash;
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
        const indexForInline = utils.findIndexInInlineLines(diffFile.highlightedDiffLines, {
          oldLineNumber,
          newLineNumber,
        });
        const prevLine = diffFile.highlightedDiffLines[indexForInline - 2];
        const prevLineNumber = (prevLine && prevLine.newLine) || 0;

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
    <span
      v-if="isMatchLine"
      @click="handleLoadMoreLines"
      class="context-cell"
      role="button"
    >...</span>
    <template
      v-else
    >
      <button
        v-if="shouldShowCommentButton"
        @click="handleCommentButton"
        type="button"
        class="add-diff-note js-add-diff-note-button"
        title="Add a comment to this line"
      >
        <icon
          name="comment"
          :size="12"
        />
      </button>
      <a
        v-if="lineNumber"
        :data-linenumber="lineNumber"
        :href="lineHref"
      >
      </a>
      <diff-gutter-avatars
        v-if="shouldShowAvatarsOnGutter"
        :discussions="discussions"
      />
    </template>
  </div>
</template>
