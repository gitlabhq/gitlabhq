<!-- eslint-disable vue/multi-word-component-names -->
<script>
import Vue from 'vue';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { createAlert } from '~/alert';
import { __ } from '~/locale';
import SuggestionDiff from './suggestion_diff.vue';

// eslint-disable-next-line vue/one-component-per-file
export default {
  directives: {
    SafeHtml,
  },
  props: {
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
    batchSuggestionsInfo: {
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
    // eslint-disable-next-line vue/no-unused-properties -- false positive
    defaultCommitMessage: {
      type: String,
      required: false,
      default: null,
    },
    // eslint-disable-next-line vue/no-unused-properties -- false positive
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
    failedToLoadMetadata() {
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
        createAlert({
          message: __('Unable to apply suggestions to a deleted line.'),
          parent: this.$el,
        });
      }

      suggestionElements.forEach((suggestionEl, i) => {
        const suggestionParentEl = suggestionEl.parentElement;
        const diffComponent = this.generateDiff(i);
        diffComponent.$mount(suggestionParentEl);
      });

      this.isRendered = true;
    },
    generateDiff(suggestionIndex) {
      const {
        suggestions,
        disabled,
        batchSuggestionsInfo,
        helpPagePath,
        failedToLoadMetadata,
        $el,
      } = this;
      const suggestion =
        suggestions && suggestions[suggestionIndex] ? suggestions[suggestionIndex] : {};

      const emitOnRoot = (...args) => this.$emit(...args);
      // eslint-disable-next-line vue/one-component-per-file
      const SuggestionDiffComponent = Vue.extend({
        computed: {
          suggestionsCount: () => this.suggestionsCount,
          defaultCommitMessage: () => this.defaultCommitMessage || '',
        },
        render(h) {
          return h(SuggestionDiff, {
            props: {
              disabled,
              suggestion,
              batchSuggestionsInfo,
              helpPagePath,
              failedToLoadMetadata,
              suggestionsCount: this.suggestionsCount,
              defaultCommitMessage: this.defaultCommitMessage,
            },
            on: {
              apply: ({ suggestionId, callback, message }) =>
                emitOnRoot('apply', { suggestionId, callback, flashContainer: $el, message }),
              applyBatch: (message) => emitOnRoot('applyBatch', { message, flashContainer: $el }),
              addToBatch: (suggestionId) => emitOnRoot('addToBatch', suggestionId),
              removeFromBatch: (suggestionId) => emitOnRoot('removeFromBatch', suggestionId),
            },
          });
        },
      });

      const suggestionDiff = new SuggestionDiffComponent();
      return suggestionDiff;
    },
    reset() {
      // resets the container HTML (replaces it with the updated noteHTML)
      // calls `renderSuggestions` once the updated noteHTML is added to the DOM

      // eslint-disable-next-line no-unsanitized/property
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
    <div class="flash-container js-suggestions-flash gl-whitespace-pre-line"></div>
    <div
      v-show="isRendered"
      ref="container"
      v-safe-html="noteHtml"
      data-testid="suggestions-container"
      class="md suggestions"
    ></div>
  </div>
</template>
