<script>
import { mapState, mapGetters, mapActions } from 'vuex';
import diffLineNoteFormMixin from 'ee_else_ce/notes/mixins/diff_line_note_form';
import { s__ } from '~/locale';
import noteForm from '../../notes/components/note_form.vue';
import autosave from '../../notes/mixins/autosave';
import userAvatarLink from '../../vue_shared/components/user_avatar/user_avatar_link.vue';
import { DIFF_NOTE_TYPE } from '../constants';

export default {
  components: {
    noteForm,
    userAvatarLink,
  },
  mixins: [autosave, diffLineNoteFormMixin],
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
  computed: {
    ...mapState({
      noteableData: state => state.notes.noteableData,
      diffViewType: state => state.diffs.diffViewType,
    }),
    ...mapState('diffs', ['showSuggestPopover']),
    ...mapGetters('diffs', ['getDiffFileByHash']),
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
      };
    },
    diffFile() {
      return this.getDiffFileByHash(this.diffFileHash);
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
  },
  methods: {
    ...mapActions('diffs', [
      'cancelCommentForm',
      'assignDiscussionsToDiff',
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
    <user-avatar-link
      v-if="author"
      :link-href="author.path"
      :img-src="author.avatar_url"
      :img-alt="author.name"
      :img-size="40"
      class="d-none d-sm-block"
    />
    <note-form
      ref="noteForm"
      :is-editing="true"
      :line-code="line.line_code"
      :line="line"
      :help-page-path="helpPagePath"
      :diff-file="diffFile"
      :show-suggest-popover="showSuggestPopover"
      save-button-title="Comment"
      class="diff-comment-form"
      @handleFormUpdateAddToReview="addToReview"
      @cancelForm="handleCancelCommentForm"
      @handleFormUpdate="handleSaveNote"
      @handleSuggestDismissed="setSuggestPopoverDismissed"
    />
  </div>
</template>
