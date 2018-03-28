<script>
import { mapState, mapGetters, mapActions } from 'vuex';
import Icon from '~/vue_shared/components/icon.vue';
import DiffGutterAvatars from './diff_gutter_avatars.vue';
import { MATCH_LINE_TYPE, UNFOLD_COUNT, CONTEXT_LINE_TYPE } from '../constants';
import * as utils from '../store/utils';

export default {
  props: {
    fileHash: {
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
    contextLinesPath: {
      type: String,
      required: true,
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
    getLineHref() {
      return this.lineCode ? `#${this.lineCode}` : '#';
    },
    shouldShowCommentButton() {
      return (
        this.isLoggedIn &&
        this.showCommentButton &&
        !this.isMatchLine &&
        !this.isContextLine &&
        !this.hasDiscussions
      );
    },
    discussions() {
      return this.discussionsByLineCode[this.lineCode] || [];
    },
    hasDiscussions() {
      return this.discussions.length > 0;
    },
  },
  methods: {
    ...mapActions(['loadMoreLines']),
    handleCommentButton() {
      this.$emit('showCommentForm', {
        lineCode: this.lineCode,
        linePosition: this.linePosition,
      });
    },
    handleLoadMoreLines() {
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
      this.loadMoreLines({ endpoint, params, lineNumbers, fileHash });
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
        :href="getLineHref"
      >
      </a>
      <diff-gutter-avatars
        v-if="hasDiscussions && showCommentButton"
        :discussions="discussions"
      />
    </template>
  </div>
</template>
