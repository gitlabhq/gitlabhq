import { mapActions, mapGetters, mapState } from 'vuex';
import { getDraftReplyFormData, getDraftFormData } from '~/batch_comments/utils';
import { TEXT_DIFF_POSITION_TYPE, IMAGE_DIFF_POSITION_TYPE } from '~/diffs/constants';
import createFlash from '~/flash';
import { clearDraft } from '~/lib/utils/autosave';
import { s__ } from '~/locale';
import { formatLineRange } from '~/notes/components/multiline_comment_utils';

export default {
  computed: {
    ...mapState({
      noteableData: (state) => state.notes.noteableData,
      notesData: (state) => state.notes.notesData,
      withBatchComments: (state) => state.batchComments?.withBatchComments,
    }),
    ...mapGetters('diffs', ['getDiffFileByHash']),
    ...mapGetters('batchComments', ['shouldRenderDraftRowInDiscussion', 'draftForDiscussion']),
    ...mapState('diffs', ['commit']),
  },
  methods: {
    ...mapActions('diffs', ['cancelCommentForm']),
    ...mapActions('batchComments', ['addDraftToReview', 'saveDraft', 'insertDraftIntoDrafts']),
    addReplyToReview(noteText, isResolving) {
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

      this.isReplying = false;

      this.saveDraft(postData)
        .then(() => {
          this.handleClearForm(this.discussion.line_code);
        })
        .catch(() => {
          createFlash({
            message: s__('MergeRequests|An error occurred while saving the draft comment.'),
          });
        });
    },
    addToReview(note) {
      const lineRange =
        (this.line && this.commentLineStart && formatLineRange(this.commentLineStart, this.line)) ||
        {};
      const positionType = this.diffFileCommentForm
        ? IMAGE_DIFF_POSITION_TYPE
        : TEXT_DIFF_POSITION_TYPE;
      const selectedDiffFile = this.getDiffFileByHash(this.diffFileHash);
      const postData = getDraftFormData({
        note,
        notesData: this.notesData,
        noteableData: this.noteableData,
        noteableType: this.noteableType,
        noteTargetLine: this.noteTargetLine,
        diffViewType: this.diffViewType,
        diffFile: selectedDiffFile,
        linePosition: this.position,
        positionType,
        ...this.diffFileCommentForm,
        lineRange,
      });

      const diffFileHeadSha = this.commit && this?.diffFile?.diff_refs?.head_sha;

      postData.data.note.commit_id = diffFileHeadSha || null;

      return this.saveDraft(postData)
        .then(() => {
          if (positionType === IMAGE_DIFF_POSITION_TYPE) {
            this.closeDiffFileCommentForm(this.diffFileHash);
          } else {
            this.handleClearForm(this.line.line_code);
          }
        })
        .catch(() => {
          createFlash({
            message: s__('MergeRequests|An error occurred while saving the draft comment.'),
          });
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
      return this.withBatchComments && this.shouldRenderDraftRowInDiscussion(replyId);
    },
  },
};
