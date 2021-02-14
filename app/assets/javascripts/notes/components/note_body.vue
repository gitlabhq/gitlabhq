<script>
/* eslint-disable vue/no-v-html */
import $ from 'jquery';
import { escape } from 'lodash';
import { mapActions, mapGetters, mapState } from 'vuex';

import '~/behaviors/markdown/render_gfm';
import Suggestions from '~/vue_shared/components/markdown/suggestions.vue';
import autosave from '../mixins/autosave';
import noteAttachment from './note_attachment.vue';
import noteAwardsList from './note_awards_list.vue';
import noteEditedText from './note_edited_text.vue';
import noteForm from './note_form.vue';

export default {
  components: {
    noteEditedText,
    noteAwardsList,
    noteAttachment,
    noteForm,
    Suggestions,
  },
  mixins: [autosave],
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
  },
  computed: {
    ...mapGetters(['getDiscussion', 'suggestionsCount']),
    ...mapGetters('diffs', ['suggestionCommitMessage']),
    discussion() {
      if (!this.note.isDraft) return {};

      return this.getDiscussion(this.note.discussion_id);
    },
    ...mapState({
      batchSuggestionsInfo: (state) => state.notes.batchSuggestionsInfo,
    }),
    noteBody() {
      return this.note.note;
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
      const suggestionsCount = 1;
      const filesCount = 1;
      const filePaths = this.file ? [this.file.file_path] : [];
      const suggestion = this.suggestionCommitMessage({
        file_paths: filePaths.join(', '),
        suggestions_count: suggestionsCount,
        files_count: filesCount,
      });

      return escape(suggestion);
    },
  },
  mounted() {
    this.renderGFM();

    if (this.isEditing) {
      this.initAutoSave(this.note);
    }
  },
  updated() {
    this.renderGFM();

    if (this.isEditing) {
      if (!this.autosave) {
        this.initAutoSave(this.note);
      } else {
        this.setAutoSave();
      }
    }
  },
  methods: {
    ...mapActions([
      'submitSuggestion',
      'submitSuggestionBatch',
      'addSuggestionInfoToBatch',
      'removeSuggestionInfoFromBatch',
    ]),
    renderGFM() {
      $(this.$refs['note-body']).renderGFM();
    },
    handleFormUpdate(note, parentElement, callback, resolveDiscussion) {
      this.$emit('handleFormUpdate', note, parentElement, callback, resolveDiscussion);
    },
    formCancelHandler(shouldConfirm, isDirty) {
      this.$emit('cancelForm', shouldConfirm, isDirty);
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
    applySuggestionBatch({ flashContainer }) {
      return this.submitSuggestionBatch({ flashContainer });
    },
    addSuggestionToBatch(suggestionId) {
      const { discussion_id: discussionId, id: noteId } = this.note;

      this.addSuggestionInfoToBatch({ suggestionId, discussionId, noteId });
    },
    removeSuggestionFromBatch(suggestionId) {
      this.removeSuggestionInfoFromBatch(suggestionId);
    },
  },
};
</script>

<template>
  <div ref="note-body" :class="{ 'js-task-list-container': canEdit }" class="note-body">
    <suggestions
      v-if="hasSuggestion && !isEditing"
      :suggestions="note.suggestions"
      :suggestions-count="suggestionsCount"
      :batch-suggestions-info="batchSuggestionsInfo"
      :note-html="note.note_html"
      :line-type="lineType"
      :help-page-path="helpPagePath"
      :default-commit-message="commitMessage"
      @apply="applySuggestion"
      @applyBatch="applySuggestionBatch"
      @addToBatch="addSuggestionToBatch"
      @removeFromBatch="removeSuggestionFromBatch"
    />
    <div v-else class="note-text md" v-html="note.note_html"></div>
    <note-form
      v-if="isEditing"
      ref="noteForm"
      :is-editing="isEditing"
      :note-body="noteBody"
      :note-id="note.id"
      :line="line"
      :note="note"
      :help-page-path="helpPagePath"
      :discussion="discussion"
      :resolve-discussion="note.resolve_discussion"
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
      v-if="note.last_edited_at"
      :edited-at="note.last_edited_at"
      :edited-by="note.last_edited_by"
      action-text="Edited"
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
