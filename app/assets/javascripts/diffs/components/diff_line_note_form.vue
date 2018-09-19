<script>
import { mapState, mapGetters, mapActions } from 'vuex';
import createFlash from '~/flash';
import { s__ } from '~/locale';
import noteForm from '../../notes/components/note_form.vue';
import { getNoteFormData } from '../store/utils';
import autosave from '../../notes/mixins/autosave';
import { DIFF_NOTE_TYPE } from '../constants';
import { reduceDiscussionsToLineCodes } from '../../notes/stores/utils';

export default {
  components: {
    noteForm,
  },
  mixins: [autosave],
  props: {
    diffFileHash: {
      type: String,
      required: true,
    },
    line: {
      type: Object,
      required: true,
    },
    position: {
      type: String,
      required: false,
      default: '',
    },
    noteTargetLine: {
      type: Object,
      required: true,
    },
  },
  computed: {
    ...mapState({
      noteableData: state => state.notes.noteableData,
      diffViewType: state => state.diffs.diffViewType,
    }),
    ...mapGetters('diffs', ['getDiffFileByHash']),
    ...mapGetters(['isLoggedIn', 'noteableType', 'getNoteableData', 'getNotesDataByProp']),
  },
  mounted() {
    if (this.isLoggedIn) {
      const keys = [
        this.noteableData.diff_head_sha,
        DIFF_NOTE_TYPE,
        this.noteableData.source_project_id,
        this.line.lineCode,
      ];

      this.initAutoSave(this.noteableData, keys);
    }
  },
  methods: {
    ...mapActions('diffs', ['cancelCommentForm', 'assignDiscussionsToDiff']),
    ...mapActions(['saveNote', 'refetchDiscussionById']),
    handleCancelCommentForm(shouldConfirm, isDirty) {
      if (shouldConfirm && isDirty) {
        const msg = s__('Notes|Are you sure you want to cancel creating this comment?');

        // eslint-disable-next-line no-alert
        if (!window.confirm(msg)) {
          return;
        }
      }

      this.cancelCommentForm({
        lineCode: this.line.lineCode,
      });
      this.$nextTick(() => {
        this.resetAutoSave();
      });
    },
    handleSaveNote(note) {
      const selectedDiffFile = this.getDiffFileByHash(this.diffFileHash);
      const postData = getNoteFormData({
        note,
        noteableData: this.noteableData,
        noteableType: this.noteableType,
        noteTargetLine: this.noteTargetLine,
        diffViewType: this.diffViewType,
        diffFile: selectedDiffFile,
        linePosition: this.position,
      });

      this.saveNote(postData)
        .then(result => {
          const endpoint = this.getNotesDataByProp('discussionsPath');

          this.refetchDiscussionById({ path: endpoint, discussionId: result.discussion_id })
            .then(selectedDiscussion => {
              const lineCodeDiscussions = reduceDiscussionsToLineCodes([selectedDiscussion]);
              this.assignDiscussionsToDiff(lineCodeDiscussions);

              this.handleCancelCommentForm();
            })
            .catch(() => {
              createFlash(s__('MergeRequests|Updating discussions failed'));
            });
        })
        .catch(() => {
          createFlash(s__('MergeRequests|Saving the comment failed'));
        });
    },
  },
};
</script>

<template>
  <div
    class="content discussion-form discussion-form-container discussion-notes"
  >
    <note-form
      ref="noteForm"
      :is-editing="true"
      :line-code="line.lineCode"
      save-button-title="Comment"
      class="diff-comment-form"
      @cancelForm="handleCancelCommentForm"
      @handleFormUpdate="handleSaveNote"
    />
  </div>
</template>
