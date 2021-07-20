<script>
import { mapState, mapGetters, mapActions } from 'vuex';
import { s__ } from '~/locale';
import diffLineNoteFormMixin from '~/notes/mixins/diff_line_note_form';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import MultilineCommentForm from '../../notes/components/multiline_comment_form.vue';
import {
  commentLineOptions,
  formatLineRange,
} from '../../notes/components/multiline_comment_utils';
import noteForm from '../../notes/components/note_form.vue';
import autosave from '../../notes/mixins/autosave';
import {
  DIFF_NOTE_TYPE,
  INLINE_DIFF_LINES_KEY,
  PARALLEL_DIFF_VIEW_TYPE,
  OLD_LINE_TYPE,
} from '../constants';

export default {
  components: {
    noteForm,
    MultilineCommentForm,
  },
  mixins: [autosave, diffLineNoteFormMixin, glFeatureFlagsMixin()],
  props: {
    diffFileHash: {
      type: String,
      required: true,
    },
    line: {
      type: Object,
      required: true,
    },
    linePosition: {
      type: String,
      required: false,
      default: '',
    },
    noteTargetLine: {
      type: Object,
      required: true,
    },
    helpPagePath: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      commentLineStart: {
        line_code: this.line.line_code,
        type: this.line.type,
        old_line: this.line.old_line,
        new_line: this.line.new_line,
      },
    };
  },
  computed: {
    ...mapState({
      diffViewType: ({ diffs }) => diffs.diffViewType,
      showSuggestPopover: ({ diffs }) => diffs.showSuggestPopover,
      noteableData: ({ notes }) => notes.noteableData,
      selectedCommentPosition: ({ notes }) => notes.selectedCommentPosition,
    }),
    ...mapGetters('diffs', ['getDiffFileByHash', 'diffLines']),
    ...mapGetters([
      'isLoggedIn',
      'noteableType',
      'getNoteableData',
      'getNotesDataByProp',
      'getUserData',
    ]),
    author() {
      return this.getUserData;
    },
    formData() {
      return {
        noteableData: this.noteableData,
        noteableType: this.noteableType,
        noteTargetLine: this.noteTargetLine,
        diffViewType: this.diffViewType,
        diffFile: this.diffFile,
        linePosition: this.linePosition,
        lineRange: formatLineRange(this.commentLineStart, this.line),
      };
    },
    diffFile() {
      return this.getDiffFileByHash(this.diffFileHash);
    },
    commentLineOptions() {
      const combineSides = (acc, { left, right }) => {
        // ignore null values match lines
        if (left) acc.push(left);
        // if the line_codes are identically, return to avoid duplicates
        if (
          left?.line_code === right?.line_code ||
          left?.type === 'old-nonewline' ||
          right?.type === 'new-nonewline'
        ) {
          return acc;
        }
        if (right && right.type !== 'match') acc.push(right);
        return acc;
      };
      const getDiffLines = () => {
        if (this.diffViewType === PARALLEL_DIFF_VIEW_TYPE) {
          return this.diffLines(this.diffFile).reduce(combineSides, []);
        }

        return this.diffFile[INLINE_DIFF_LINES_KEY];
      };
      const side = this.line.type === 'new' ? 'right' : 'left';
      const lines = getDiffLines();
      return commentLineOptions(lines, this.line, this.line.line_code, side);
    },
    commentLines() {
      if (!this.selectedCommentPosition) return [];

      const lines = [];
      const { start, end } = this.selectedCommentPosition;
      const diffLines = this.diffFile[INLINE_DIFF_LINES_KEY];
      let isAdding = false;

      for (let i = 0, diffLinesLength = diffLines.length - 1; i <= diffLinesLength; i += 1) {
        const line = diffLines[i];

        if (start.line_code === line.line_code) {
          isAdding = true;
        }

        if (isAdding) {
          if (line.type !== OLD_LINE_TYPE) {
            lines.push(line);
          }

          if (end.line_code === line.line_code) {
            break;
          }
        }
      }

      return lines;
    },
  },
  mounted() {
    if (this.isLoggedIn) {
      const keys = [
        this.noteableData.diff_head_sha,
        DIFF_NOTE_TYPE,
        this.noteableData.source_project_id,
        this.line.line_code,
      ];

      this.initAutoSave(this.noteableData, keys);
    }

    if (this.selectedCommentPosition) {
      this.commentLineStart = this.selectedCommentPosition.start;
    }
  },
  methods: {
    ...mapActions('diffs', [
      'cancelCommentForm',
      'saveDiffDiscussion',
      'setSuggestPopoverDismissed',
    ]),
    handleCancelCommentForm(shouldConfirm, isDirty) {
      if (shouldConfirm && isDirty) {
        const msg = s__('Notes|Are you sure you want to cancel creating this comment?');

        // eslint-disable-next-line no-alert
        if (!window.confirm(msg)) {
          return;
        }
      }

      this.cancelCommentForm({
        lineCode: this.line.line_code,
        fileHash: this.diffFileHash,
      });
      this.$nextTick(() => {
        this.resetAutoSave();
      });
    },
    handleSaveNote(note) {
      return this.saveDiffDiscussion({ note, formData: this.formData }).then(() =>
        this.handleCancelCommentForm(),
      );
    },
  },
};
</script>

<template>
  <div class="content discussion-form discussion-form-container discussion-notes">
    <div class="gl-mb-3 gl-text-gray-500 gl-pb-3">
      <multiline-comment-form
        v-model="commentLineStart"
        :line="line"
        :comment-line-options="commentLineOptions"
      />
    </div>
    <note-form
      ref="noteForm"
      :is-editing="false"
      :line-code="line.line_code"
      :line="line"
      :lines="commentLines"
      :help-page-path="helpPagePath"
      :diff-file="diffFile"
      :show-suggest-popover="showSuggestPopover"
      :save-button-title="__('Comment')"
      class="diff-comment-form gl-mt-3"
      @handleFormUpdateAddToReview="addToReview"
      @cancelForm="handleCancelCommentForm"
      @handleFormUpdate="handleSaveNote"
      @handleSuggestDismissed="setSuggestPopoverDismissed"
    />
  </div>
</template>
