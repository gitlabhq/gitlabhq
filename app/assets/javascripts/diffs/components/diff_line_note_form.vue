<script>
import { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapGetters, mapActions } from 'vuex';
import { s__, __, sprintf } from '~/locale';
import { createAlert } from '~/alert';
import diffLineNoteFormMixin from '~/notes/mixins/diff_line_note_form';
import { clearDraft } from '~/lib/utils/autosave';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { ignoreWhilePending } from '~/lib/utils/ignore_while_pending';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import MultilineCommentForm from '~/notes/components/multiline_comment_form.vue';
import { commentLineOptions, formatLineRange } from '~/notes/components/multiline_comment_utils';
import NoteForm from '~/notes/components/note_form.vue';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import {
  DIFF_NOTE_TYPE,
  INLINE_DIFF_LINES_KEY,
  PARALLEL_DIFF_VIEW_TYPE,
  OLD_LINE_TYPE,
} from '../constants';
import { SAVING_THE_COMMENT_FAILED, SOMETHING_WENT_WRONG } from '../i18n';

export default {
  components: {
    NoteForm,
    MultilineCommentForm,
  },
  mixins: [diffLineNoteFormMixin, glFeatureFlagsMixin()],
  props: {
    diffFileHash: {
      type: String,
      required: true,
    },
    line: {
      type: Object,
      required: true,
    },
    range: {
      type: Object,
      required: false,
      default: null,
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
      lines: null,
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
      const lines = [];
      const { start, end } = this.lines;
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
    autosaveKey() {
      if (!this.isLoggedIn) return '';

      const {
        id,
        noteable_type: noteableTypeUnderscored,
        noteableType,
        diff_head_sha: diffHeadSha,
        source_project_id: sourceProjectId,
      } = this.noteableData;

      return [
        s__('Autosave|Note'),
        capitalizeFirstCharacter(noteableTypeUnderscored || noteableType),
        id,
        diffHeadSha,
        DIFF_NOTE_TYPE,
        sourceProjectId,
        this.line.line_code,
      ].join('/');
    },
  },
  created() {
    if (this.range) {
      this.lines = { ...this.range };
    } else if (this.line) {
      this.lines = { start: this.line, end: this.line };
    }
  },
  mounted() {
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
    handleCancelCommentForm: ignoreWhilePending(
      async function handleCancelCommentForm(shouldConfirm, isDirty) {
        if (shouldConfirm && isDirty) {
          const msg = s__('Notes|Are you sure you want to cancel creating this comment?');

          const confirmed = await confirmAction(msg, {
            primaryBtnText: __('Discard changes'),
            cancelBtnText: __('Continue editing'),
          });

          if (!confirmed) {
            return;
          }
        }
        this.cancelCommentForm({
          lineCode: this.line.line_code,
          fileHash: this.diffFileHash,
        });
        nextTick(() => {
          clearDraft(this.autosaveKey);
        });
      },
    ),
    handleSaveNote(note, parentElement, errorCallback) {
      return this.saveDiffDiscussion({ note, formData: this.formData })
        .then(() => this.handleCancelCommentForm())
        .catch((e) => {
          const reason = e.response?.data?.errors;
          const errorMessage = reason
            ? sprintf(SAVING_THE_COMMENT_FAILED, { reason })
            : SOMETHING_WENT_WRONG;

          createAlert({
            message: errorMessage,
            parent: parentElement,
          });

          errorCallback();
        });
    },
    updateStartLine(line) {
      this.commentLineStart = line;
      this.lines.start = line;
    },
  },
};
</script>

<template>
  <div class="content discussion-form discussion-form-container discussion-notes">
    <div class="gl-mb-3 gl-pb-3 gl-text-subtle">
      <multiline-comment-form
        :line="line"
        :line-range="lines"
        :comment-line-options="commentLineOptions"
        @input="updateStartLine"
      />
    </div>
    <note-form
      ref="noteForm"
      :line-code="line.line_code"
      :line="line"
      :lines="commentLines"
      :help-page-path="helpPagePath"
      :diff-file="diffFile"
      :show-suggest-popover="showSuggestPopover"
      :save-button-title="__('Comment')"
      :autosave-key="autosaveKey"
      :autofocus="false"
      class="diff-comment-form gl-mt-3"
      @handleFormUpdateAddToReview="addToReview"
      @cancelForm="handleCancelCommentForm"
      @handleFormUpdate="handleSaveNote"
      @handleSuggestDismissed="setSuggestPopoverDismissed"
    />
  </div>
</template>
