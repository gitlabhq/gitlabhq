<script>
import Vue from 'vue';
import SuggestionDiff from './suggestion_diff.vue';
import Flash from '~/flash';

export default {
  components: { SuggestionDiff },
  props: {
    fromLine: {
      type: Number,
      required: false,
      default: 0,
    },
    fromContent: {
      type: String,
      required: false,
      default: '',
    },
    lineType: {
      type: String,
      required: false,
      default: '',
    },
    suggestions: {
      type: Array,
      required: false,
      default: () => [],
    },
    noteHtml: {
      type: String,
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
  data() {
    return {
      isRendered: false,
    };
  },
  watch: {
    suggestions() {
      this.reset();
    },
    noteHtml() {
      this.reset();
    },
  },
  mounted() {
    this.renderSuggestions();
  },
  methods: {
    renderSuggestions() {
      // swaps out suggestion(s) markdown with rich diff components
      // (while still keeping non-suggestion markdown in place)

      if (!this.noteHtml) return;
      const { container } = this.$refs;
      const suggestionElements = container.querySelectorAll('.js-render-suggestion');

      if (this.lineType === 'old') {
        Flash('Unable to apply suggestions to a deleted line.', 'alert', this.$el);
      }

      suggestionElements.forEach((suggestionEl, i) => {
        const suggestionParentEl = suggestionEl.parentElement;
        const newLines = this.extractNewLines(suggestionParentEl);
        const diffComponent = this.generateDiff(newLines, i);
        diffComponent.$mount(suggestionParentEl);
      });

      this.isRendered = true;
    },
    extractNewLines(suggestionEl) {
      // extracts the suggested lines from the markdown
      // calculates a line number for each line

      const newLines = suggestionEl.querySelectorAll('.line');
      const fromLine = this.suggestions.length ? this.suggestions[0].from_line : this.fromLine;
      const lines = [];

      newLines.forEach((line, i) => {
        const content = `${line.innerText}\n`;
        const lineNumber = fromLine + i;
        lines.push({ content, lineNumber });
      });

      return lines;
    },
    generateDiff(newLines, suggestionIndex) {
      // generates the diff <suggestion-diff /> component
      // all `suggestion` markdown will be swapped out by this component

      const { suggestions, disabled, helpPagePath } = this;
      const suggestion =
        suggestions && suggestions[suggestionIndex] ? suggestions[suggestionIndex] : {};
      const fromContent = suggestion.from_content || this.fromContent;
      const fromLine = suggestion.from_line || this.fromLine;
      const SuggestionDiffComponent = Vue.extend(SuggestionDiff);
      const suggestionDiff = new SuggestionDiffComponent({
        propsData: { newLines, fromLine, fromContent, disabled, suggestion, helpPagePath },
      });

      suggestionDiff.$on('apply', ({ suggestionId, callback }) => {
        this.$emit('apply', { suggestionId, callback, flashContainer: this.$el });
      });

      return suggestionDiff;
    },
    reset() {
      // resets the container HTML (replaces it with the updated noteHTML)
      // calls `renderSuggestions` once the updated noteHTML is added to the DOM

      this.$refs.container.innerHTML = this.noteHtml;
      this.isRendered = false;
      this.renderSuggestions();
      this.$nextTick(() => this.renderSuggestions());
    },
  },
};
</script>

<template>
  <div>
    <div class="flash-container js-suggestions-flash"></div>
    <div v-show="isRendered" ref="container" class="md" v-html="noteHtml"></div>
  </div>
</template>
