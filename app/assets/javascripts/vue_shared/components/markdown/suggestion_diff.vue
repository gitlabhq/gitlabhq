<script>
import SuggestionDiffHeader from './suggestion_diff_header.vue';

export default {
  components: {
    SuggestionDiffHeader,
  },
  props: {
    newLines: {
      type: Array,
      required: true,
    },
    fromContent: {
      type: String,
      required: false,
      default: '',
    },
    fromLine: {
      type: Number,
      required: true,
    },
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
  methods: {
    applySuggestion(callback) {
      this.$emit('apply', { suggestionId: this.suggestion.id, callback });
    },
  },
};
</script>

<template>
  <div>
    <suggestion-diff-header
      class="qa-suggestion-diff-header"
      :can-apply="suggestion.appliable && suggestion.current_user.can_apply && !disabled"
      :is-applied="suggestion.applied"
      :help-page-path="helpPagePath"
      @apply="applySuggestion"
    />
    <table class="mb-3 md-suggestion-diff js-syntax-highlight code">
      <tbody>
        <!-- Old Line -->
        <tr class="line_holder old">
          <td class="diff-line-num old_line qa-old-diff-line-number old">{{ fromLine }}</td>
          <td class="diff-line-num new_line old"></td>
          <td class="line_content old">
            <span>{{ fromContent }}</span>
          </td>
        </tr>
        <!-- New Line(s) -->
        <tr v-for="(line, key) of newLines" :key="key" class="line_holder new">
          <td class="diff-line-num old_line new"></td>
          <td class="diff-line-num new_line qa-new-diff-line-number new">{{ line.lineNumber }}</td>
          <td class="line_content new">
            <span>{{ line.content }}</span>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>
