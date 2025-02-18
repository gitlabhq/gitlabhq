<script>
import { escape } from 'lodash';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapGetters, mapState } from 'vuex';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { __ } from '~/locale';
import Suggestions from '~/vue_shared/components/markdown/suggestions.vue';
import { renderGFM } from '~/behaviors/markdown/render_gfm';
import NoteAttachment from './note_attachment.vue';
import NoteAwardsList from './note_awards_list.vue';
import NoteEditedText from './note_edited_text.vue';
import NoteForm from './note_form.vue';

export default {
  components: {
    NoteEditedText,
    NoteAwardsList,
    NoteAttachment,
    NoteForm,
    Suggestions,
    DuoCodeReviewFeedback: () =>
      import('ee_component/notes/components/duo_code_review_feedback.vue'),
  },
  directives: {
    SafeHtml,
  },
  props: {
    note: {
      type: Object,
      required: true,
    },
    line: {
      type: Object,
      required: false,
      default: null,
    },
    file: {
      type: Object,
      required: false,
      default: null,
    },
    canEdit: {
      type: Boolean,
      required: true,
    },
    isEditing: {
      type: Boolean,
      required: false,
      default: false,
    },
    helpPagePath: {
      type: String,
      required: false,
      default: '',
    },
    autosaveKey: {
      type: String,
      required: false,
      default: '',
    },
    restoreFromAutosave: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    ...mapGetters(['getDiscussion', 'suggestionsCount', 'getSuggestionsFilePaths']),
    ...mapGetters('diffs', ['suggestionCommitMessage']),
    ...mapState({
      batchSuggestionsInfo: (state) => state.notes.batchSuggestionsInfo,
      failedToLoadMetadata: (state) => state.page.failedToLoadMetadata,
    }),
    discussion() {
      if (!this.note.isDraft) return {};

      return this.getDiscussion(this.note.discussion_id);
    },
    noteBody() {
      return this.note.note;
    },
    saveButtonTitle() {
      return this.note.internal ? __('Save internal note') : __('Save comment');
    },
    hasSuggestion() {
      return this.note.suggestions && this.note.suggestions.length;
    },
    lineType() {
      return this.line ? this.line.type : null;
    },
    commitMessage() {
      // Please see this issue comment for why these
      //  are hard-coded to 1:
      //  https://gitlab.com/gitlab-org/gitlab/-/issues/291027#note_468308022
      const suggestionsCount = this.batchSuggestionsInfo.length || 1;
      const batchFilePaths = this.getSuggestionsFilePaths();
      const filePaths = batchFilePaths.length ? batchFilePaths : [this.file.file_path];
      const filesCount = filePaths.length;
      // Can be potentially replaced by calculated co-authors of a particular suggestion or batched suggestion
      const coAuthoredByTrailer = __('Co-authored-by: ...');
      const suggestion = this.suggestionCommitMessage({
        file_paths: filePaths.join(', '),
        suggestions_count: suggestionsCount,
        files_count: filesCount,
        co_authored_by: coAuthoredByTrailer,
      });

      return escape(suggestion);
    },
  },
  mounted() {
    this.renderGFM();
  },
  updated() {
    this.renderGFM();
  },
  methods: {
    ...mapActions([
      'submitSuggestion',
      'submitSuggestionBatch',
      'addSuggestionInfoToBatch',
      'removeSuggestionInfoFromBatch',
    ]),
    renderGFM() {
      renderGFM(this.$refs['note-body']);
    },
    // eslint-disable-next-line max-params
    handleFormUpdate(noteText, parentElement, callback, resolveDiscussion) {
      this.$emit('handleFormUpdate', { noteText, parentElement, callback, resolveDiscussion });
    },
    formCancelHandler(shouldConfirm, isDirty) {
      this.$emit('cancelForm', { shouldConfirm, isDirty });
    },
    applySuggestion({ suggestionId, flashContainer, callback = () => {}, message }) {
      const { discussion_id: discussionId, id: noteId } = this.note;

      return this.submitSuggestion({
        discussionId,
        noteId,
        suggestionId,
        flashContainer,
        message,
      }).then(callback);
    },
    applySuggestionBatch({ message, flashContainer }) {
      return this.submitSuggestionBatch({ message, flashContainer });
    },
    addSuggestionToBatch(suggestionId) {
      const { discussion_id: discussionId, id: noteId } = this.note;

      this.addSuggestionInfoToBatch({ suggestionId, discussionId, noteId });
    },
    removeSuggestionFromBatch(suggestionId) {
      this.removeSuggestionInfoFromBatch(suggestionId);
    },
  },
  safeHtmlConfig: {
    ADD_TAGS: ['use', 'gl-emoji', 'copy-code'],
  },
};
</script>

<template>
  <div
    ref="note-body"
    :class="{
      'js-task-list-container': canEdit,
    }"
    class="note-body"
  >
    <suggestions
      v-if="hasSuggestion && !isEditing"
      :suggestions="note.suggestions"
      :suggestions-count="suggestionsCount"
      :batch-suggestions-info="batchSuggestionsInfo"
      :note-html="note.note_html"
      :line-type="lineType"
      :help-page-path="helpPagePath"
      :default-commit-message="commitMessage"
      :failed-to-load-metadata="failedToLoadMetadata"
      @apply="applySuggestion"
      @applyBatch="applySuggestionBatch"
      @addToBatch="addSuggestionToBatch"
      @removeFromBatch="removeSuggestionFromBatch"
    />
    <div v-else v-safe-html:[$options.safeHtmlConfig]="note.note_html" class="note-text md"></div>
    <duo-code-review-feedback
      v-if="note.author.user_type === 'duo_code_review_bot' && note.type !== 'DiffNote'"
      class="gl-mt-3"
      data-testid="code-review-feedback"
    />
    <note-form
      v-if="isEditing"
      ref="noteForm"
      :note-body="noteBody"
      :note-id="note.id"
      :line="line"
      :note="note"
      :diff-file="file"
      :save-button-title="saveButtonTitle"
      :help-page-path="helpPagePath"
      :discussion="discussion"
      :resolve-discussion="note.resolve_discussion"
      :autosave-key="autosaveKey"
      :restore-from-autosave="restoreFromAutosave"
      @handleFormUpdate="handleFormUpdate"
      @cancelForm="formCancelHandler"
    />
    <!-- eslint-disable vue/no-mutating-props -->
    <textarea
      v-if="canEdit"
      v-model="note.note"
      :data-update-url="note.path"
      class="hidden js-task-list-field"
      dir="auto"
    ></textarea>
    <!-- eslint-enable vue/no-mutating-props -->
    <note-edited-text
      v-if="note.last_edited_at && note.last_edited_at !== note.created_at"
      :edited-at="note.last_edited_at"
      :edited-by="note.last_edited_by"
      :action-text="__('Edited')"
      class="note_edited_ago"
    />
    <note-awards-list
      v-if="note.award_emoji && note.award_emoji.length"
      :note-id="note.id"
      :note-author-id="note.author.id"
      :awards="note.award_emoji"
      :toggle-award-path="note.toggle_award_path"
      :can-award-emoji="note.current_user.can_award_emoji"
    />
    <note-attachment v-if="note.attachment" :attachment="note.attachment" />
  </div>
</template>
