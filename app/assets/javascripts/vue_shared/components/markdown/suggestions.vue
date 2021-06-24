<script>
import { GlSafeHtmlDirective as SafeHtml } from '@gitlab/ui';
import Vue from 'vue';
import createFlash from '~/flash';
import { __ } from '~/locale';
import SuggestionDiff from './suggestion_diff.vue';

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
    defaultCommitMessage: {
      type: String,
      required: true,
    },
    suggestionsCount: {
      type: Number,
      required: false,
      default: 0,
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
  beforeDestroy() {
    if (this.suggestionsWatch) {
      this.suggestionsWatch();
    }
  },
  methods: {
    renderSuggestions() {
      // swaps out suggestion(s) markdown with rich diff components
      // (while still keeping non-suggestion markdown in place)

      if (!this.noteHtml) return;
      const { container } = this.$refs;
      const suggestionElements = container.querySelectorAll('.js-render-suggestion');

      if (this.lineType === 'old') {
        createFlash({
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
        defaultCommitMessage,
        suggestionsCount,
      } = this;
      const suggestion =
        suggestions && suggestions[suggestionIndex] ? suggestions[suggestionIndex] : {};
      const SuggestionDiffComponent = Vue.extend(SuggestionDiff);
      const suggestionDiff = new SuggestionDiffComponent({
        propsData: {
          disabled,
          suggestion,
          batchSuggestionsInfo,
          helpPagePath,
          defaultCommitMessage,
          suggestionsCount,
        },
      });

      // We're using `$watch` as `suggestionsCount` updates do not
      // propagate to this component for some unknown reason while
      // using a traditional prop watcher.
      this.suggestionsWatch = this.$watch('suggestionsCount', () => {
        suggestionDiff.suggestionsCount = this.suggestionsCount;
      });

      suggestionDiff.$on('apply', ({ suggestionId, callback, message }) => {
        this.$emit('apply', { suggestionId, callback, flashContainer: this.$el, message });
      });

      suggestionDiff.$on('applyBatch', () => {
        this.$emit('applyBatch', { flashContainer: this.$el });
      });

      suggestionDiff.$on('addToBatch', (suggestionId) => {
        this.$emit('addToBatch', suggestionId);
      });

      suggestionDiff.$on('removeFromBatch', (suggestionId) => {
        this.$emit('removeFromBatch', suggestionId);
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
    <div v-show="isRendered" ref="container" v-safe-html="noteHtml" class="md"></div>
  </div>
</template>
