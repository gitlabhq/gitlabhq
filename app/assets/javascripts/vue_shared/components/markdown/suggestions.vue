<script>
import Vue from 'vue';
import { __ } from '~/locale';
import SuggestionDiff from './suggestion_diff.vue';
import Flash from '~/flash';

export default {
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
        Flash(__('Unable to apply suggestions to a deleted line.'), 'alert', this.$el);
      }

      suggestionElements.forEach((suggestionEl, i) => {
        const suggestionParentEl = suggestionEl.parentElement;
        const diffComponent = this.generateDiff(i);
        diffComponent.$mount(suggestionParentEl);
      });

      this.isRendered = true;
    },
    generateDiff(suggestionIndex) {
      const { suggestions, disabled, helpPagePath } = this;
      const suggestion =
        suggestions && suggestions[suggestionIndex] ? suggestions[suggestionIndex] : {};
      const SuggestionDiffComponent = Vue.extend(SuggestionDiff);
      const suggestionDiff = new SuggestionDiffComponent({
        propsData: { disabled, suggestion, helpPagePath },
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
