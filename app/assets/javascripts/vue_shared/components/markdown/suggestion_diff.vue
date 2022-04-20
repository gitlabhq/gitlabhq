<script>
import { selectDiffLines } from '../lib/utils/diff_utils';
import SuggestionDiffHeader from './suggestion_diff_header.vue';
import SuggestionDiffRow from './suggestion_diff_row.vue';

export default {
  components: {
    SuggestionDiffHeader,
    SuggestionDiffRow,
  },
  props: {
    suggestion: {
      type: Object,
      required: true,
    },
    batchSuggestionsInfo: {
      type: Array,
      required: false,
      default: () => [],
    },
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    helpPagePath: {
      type: String,
      required: true,
    },
    defaultCommitMessage: {
      type: String,
      required: true,
    },
    suggestionsCount: {
      type: Number,
      required: false,
      default: 0,
    },
    failedToLoadMetadata: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    batchSuggestionsCount() {
      return this.batchSuggestionsInfo.length;
    },
    isBatched() {
      return Boolean(
        this.batchSuggestionsInfo.find(({ suggestionId }) => suggestionId === this.suggestion.id),
      );
    },
    lines() {
      return selectDiffLines(this.suggestion.diff_lines);
    },
  },
  methods: {
    applySuggestion(callback, message) {
      this.$emit('apply', { suggestionId: this.suggestion.id, callback, message });
    },
    applySuggestionBatch(message) {
      this.$emit('applyBatch', message);
    },
    addSuggestionToBatch() {
      this.$emit('addToBatch', this.suggestion.id);
    },
    removeSuggestionFromBatch() {
      this.$emit('removeFromBatch', this.suggestion.id);
    },
  },
};
</script>

<template>
  <div class="md-suggestion">
    <suggestion-diff-header
      class="js-suggestion-diff-header"
      :suggestions-count="suggestionsCount"
      :can-apply="suggestion.appliable && suggestion.current_user.can_apply && !disabled"
      :is-applied="suggestion.applied"
      :is-batched="isBatched"
      :is-applying-batch="suggestion.is_applying_batch"
      :batch-suggestions-count="batchSuggestionsCount"
      :help-page-path="helpPagePath"
      :default-commit-message="defaultCommitMessage"
      :inapplicable-reason="suggestion.inapplicable_reason"
      :failed-to-load-metadata="failedToLoadMetadata"
      @apply="applySuggestion"
      @applyBatch="applySuggestionBatch"
      @addToBatch="addSuggestionToBatch"
      @removeFromBatch="removeSuggestionFromBatch"
    />
    <table class="mb-3 md-suggestion-diff js-syntax-highlight code">
      <tbody>
        <suggestion-diff-row
          v-for="(line, index) of lines"
          :key="`${index}-${line.text}`"
          :line="line"
        />
      </tbody>
    </table>
  </div>
</template>
