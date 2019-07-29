<script>
import SuggestionDiffHeader from './suggestion_diff_header.vue';
import SuggestionDiffRow from './suggestion_diff_row.vue';
import { selectDiffLines } from '../lib/utils/diff_utils';

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
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    helpPagePath: {
      type: String,
      required: true,
    },
  },
  computed: {
    lines() {
      return selectDiffLines(this.suggestion.diff_lines);
    },
  },
  methods: {
    applySuggestion(callback) {
      this.$emit('apply', { suggestionId: this.suggestion.id, callback });
    },
  },
};
</script>

<template>
  <div class="md-suggestion">
    <suggestion-diff-header
      class="qa-suggestion-diff-header js-suggestion-diff-header"
      :can-apply="suggestion.appliable && suggestion.current_user.can_apply && !disabled"
      :is-applied="suggestion.applied"
      :help-page-path="helpPagePath"
      @apply="applySuggestion"
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
