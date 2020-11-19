<script>
import { mapState, mapGetters, mapActions } from 'vuex';
import diffLineNoteFormMixin from '~/notes/mixins/diff_line_note_form';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { s__ } from '~/locale';
import noteForm from '../../notes/components/note_form.vue';
import MultilineCommentForm from '../../notes/components/multiline_comment_form.vue';
import autosave from '../../notes/mixins/autosave';
import userAvatarLink from '../../vue_shared/components/user_avatar/user_avatar_link.vue';
import { DIFF_NOTE_TYPE, INLINE_DIFF_LINES_KEY, PARALLEL_DIFF_VIEW_TYPE } from '../constants';
import {
  commentLineOptions,
  formatLineRange,
} from '../../notes/components/multiline_comment_utils';

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
        line_code: this.line.line_code,
        type: this.line.type,
        old_line: this.line.old_line,
        new_line: this.line.new_line,
      },
    };
  },
  computed: {
    ...mapState({
      noteableData: state => state.notes.noteableData,
      diffViewType: state => state.diffs.diffViewType,
    }),
    ...mapState('diffs', ['showSuggestPopover']),
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
          return this.diffLines(this.diffFile, this.glFeatures.unifiedDiffComponents).reduce(
            combineSides,
            [],
          );
        }

        return this.diffFile[INLINE_DIFF_LINES_KEY];
      };
      const side = this.line.type === 'new' ? 'right' : 'left';
      const lines = getDiffLines();
      return commentLineOptions(lines, this.line, this.line.line_code, side);
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
    <div v-if="glFeatures.multilineComments" class="gl-mb-3 gl-text-gray-500 gl-pb-3">
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
      class="diff-comment-form gl-mt-3"
      @handleFormUpdateAddToReview="addToReview"
      @cancelForm="handleCancelCommentForm"
      @handleFormUpdate="handleSaveNote"
      @handleSuggestDismissed="setSuggestPopoverDismissed"
    />
  </div>
</template>
