<script>
import { escape } from 'lodash-es';
import { __ } from '~/locale';
import { computeSuggestionCommitMessage } from '~/diffs/utils/suggestions';
import Suggestions from '~/vue_shared/components/markdown/suggestions.vue';

export default {
  name: 'NoteSuggestions',
  components: {
    Suggestions,
  },
  inject: {
    store: { type: Object },
    suggestionsHelpPath: { default: '' },
    defaultSuggestionCommitMessage: { default: '' },
  },
  props: {
    note: {
      type: Object,
      required: true,
    },
  },
  computed: {
    commitMessage() {
      const suggestionsCount = this.store.batchSuggestionsInfo.length || 1;
      const batchFilePaths = this.store.suggestionsFilePaths;
      const filePaths = batchFilePaths.length
        ? batchFilePaths
        : [this.note.position?.new_path].filter(Boolean);
      return escape(
        computeSuggestionCommitMessage({
          message: this.defaultSuggestionCommitMessage,
          values: {
            suggestions_count: suggestionsCount,
            files_count: filePaths.length,
            file_paths: filePaths.join(', '),
            co_authored_by: __('Co-authored-by: ...'),
          },
        }),
      );
    },
  },
  methods: {
    applySuggestion({ suggestionId, flashContainer, callback = () => {}, message }) {
      const { discussion_id: discussionId, id: noteId } = this.note;
      return this.store
        .submitSuggestion({ discussionId, noteId, suggestionId, flashContainer, message })
        .then(callback);
    },
    addSuggestionToBatch(suggestionId) {
      const { discussion_id: discussionId, id: noteId } = this.note;
      this.store.addSuggestionInfoToBatch({ suggestionId, discussionId, noteId });
    },
  },
};
</script>

<template>
  <!-- eslint-disable vue/v-on-event-hyphenation -- Suggestions.vue emits camelCase events -->
  <suggestions
    class="rd-note-suggestions"
    :suggestions="note.suggestions"
    :suggestions-count="store.suggestionsCount"
    :batch-suggestions-info="store.batchSuggestionsInfo"
    :note-html="note.note_html"
    :default-commit-message="commitMessage"
    :help-page-path="suggestionsHelpPath"
    @apply="applySuggestion"
    @applyBatch="store.submitSuggestionBatch($event)"
    @addToBatch="addSuggestionToBatch"
    @removeFromBatch="store.removeSuggestionInfoFromBatch($event)"
  />
</template>
