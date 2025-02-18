import { mapState, mapActions } from 'pinia';
// eslint-disable-next-line no-restricted-imports
import {
  mapActions as mapVuexActions,
  mapGetters as mapVuexGetters,
  mapState as mapVuexState,
} from 'vuex';
import { getDraftReplyFormData, getDraftFormData } from '~/batch_comments/utils';
import {
  TEXT_DIFF_POSITION_TYPE,
  IMAGE_DIFF_POSITION_TYPE,
  FILE_DIFF_POSITION_TYPE,
} from '~/diffs/constants';
import { createAlert } from '~/alert';
import { clearDraft } from '~/lib/utils/autosave';
import { sprintf } from '~/locale';
import { formatLineRange } from '~/notes/components/multiline_comment_utils';
import { SAVING_THE_COMMENT_FAILED, SOMETHING_WENT_WRONG } from '~/diffs/i18n';
import { useBatchComments } from '~/batch_comments/store';

export default {
  computed: {
    ...mapVuexState({
      noteableData: (state) => state.notes.noteableData,
      notesData: (state) => state.notes.notesData,
    }),
    ...mapVuexGetters('diffs', ['getDiffFileByHash']),
    ...mapState(useBatchComments, [
      'shouldRenderDraftRowInDiscussion',
      'draftForDiscussion',
      'isMergeRequest',
    ]),
    ...mapVuexState('diffs', ['commit', 'showWhitespace']),
  },
  methods: {
    ...mapVuexActions('diffs', ['cancelCommentForm', 'toggleFileCommentForm']),
    ...mapActions(useBatchComments, ['addDraftToReview', 'saveDraft', 'insertDraftIntoDrafts']),
    // eslint-disable-next-line max-params
    addReplyToReview(noteText, isResolving, parentElement, errorCallback) {
      const postData = getDraftReplyFormData({
        in_reply_to_discussion_id: this.discussion.reply_id,
        target_type: this.getNoteableData.targetType,
        notesData: this.notesData,
        draft_note: {
          note: noteText,
          resolve_discussion: isResolving,
        },
      });

      if (this.discussion.for_commit) {
        postData.note_project_id = this.discussion.project_id;
      }

      this.saveDraft(postData)
        .then(() => {
          this.isReplying = false;
          this.handleClearForm(this.discussion.line_code);
        })
        .catch((response) => {
          const reason = response?.data?.errors;
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
    // eslint-disable-next-line max-params
    addToReview(note, positionType = null, parentElement, errorCallback) {
      const lineRange =
        (this.line && this.commentLineStart && formatLineRange(this.commentLineStart, this.line)) ||
        {};
      const position =
        positionType ||
        (this.diffFileCommentForm ? IMAGE_DIFF_POSITION_TYPE : TEXT_DIFF_POSITION_TYPE);
      const diffFile = this.diffFile || this.file;
      const postData = getDraftFormData({
        note,
        notesData: this.notesData,
        noteableData: this.noteableData,
        noteableType: this.noteableType,
        noteTargetLine: this.noteTargetLine,
        diffViewType: this.diffViewType,
        diffFile,
        linePosition: this.position,
        positionType: position,
        ...this.diffFileCommentForm,
        lineRange,
        showWhitespace: this.showWhitespace,
      });

      const diffFileHeadSha = this.commit && diffFile?.diff_refs?.head_sha;

      postData.data.note.commit_id = diffFileHeadSha || null;

      return this.saveDraft(postData)
        .then(() => {
          if (position === IMAGE_DIFF_POSITION_TYPE) {
            this.closeDiffFileCommentForm(this.diffFileHash);
          } else if (this.line?.line_code) {
            this.handleClearForm(this.line.line_code);
          } else if (position === FILE_DIFF_POSITION_TYPE) {
            this.toggleFileCommentForm(diffFile.file_path);
          }
        })
        .catch((response) => {
          const reason = response?.data?.errors;
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
    handleClearForm(lineCode) {
      this.cancelCommentForm({
        lineCode,
        fileHash: this.diffFileHash,
      });
      this.$nextTick(() => {
        if (this.autosaveKey) {
          clearDraft(this.autosaveKey);
        } else {
          // TODO: remove the following after replacing the autosave mixin
          // https://gitlab.com/gitlab-org/gitlab-foss/issues/60587
          this.resetAutoSave();
        }
      });
    },
    showDraft(replyId) {
      return this.isMergeRequest && this.shouldRenderDraftRowInDiscussion(replyId);
    },
  },
};
