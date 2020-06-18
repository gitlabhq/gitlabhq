<script>
import { mapState, mapGetters, mapActions } from 'vuex';
import diffLineNoteFormMixin from '~/notes/mixins/diff_line_note_form';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { s__ } from '~/locale';
import noteForm from '../../notes/components/note_form.vue';
import MultilineCommentForm from '../../notes/components/multiline_comment_form.vue';
import autosave from '../../notes/mixins/autosave';
import userAvatarLink from '../../vue_shared/components/user_avatar/user_avatar_link.vue';
import { DIFF_NOTE_TYPE } from '../constants';
import { commentLineOptions } from '../../notes/components/multiline_comment_utils';

export default {
  components: {
    noteForm,
    userAvatarLink,
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
        lineCode: this.line.line_code,
        type: this.line.type,
      },
    };
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
        lineRange: {
          start_line_code: this.commentLineStart.lineCode,
          start_line_type: this.commentLineStart.type,
          end_line_code: this.line.line_code,
          end_line_type: this.line.type,
        },
      };
    },
    diffFile() {
      return this.getDiffFileByHash(this.diffFileHash);
    },
    commentLineOptions() {
      return commentLineOptions(this.diffFile.highlighted_diff_lines, this.line.line_code);
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
    <div
      v-if="glFeatures.multilineComments"
      class="gl-mb-3 gl-text-gray-700 gl-border-gray-200 gl-border-b-solid gl-border-b-1 gl-pb-3"
    >
      <multiline-comment-form
        v-model="commentLineStart"
        :line="line"
        :comment-line-options="commentLineOptions"
      />
    </div>
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
      class="diff-comment-form prepend-top-10"
      @handleFormUpdateAddToReview="addToReview"
      @cancelForm="handleCancelCommentForm"
      @handleFormUpdate="handleSaveNote"
      @handleSuggestDismissed="setSuggestPopoverDismissed"
    />
  </div>
</template>
