<script>
import { uniqueId } from 'lodash';
import { GlButton, GlFormGroup, GlFormInput } from '@gitlab/ui';

export default {
  name: 'CiKeyField',
  components: {
    GlButton,
    GlFormGroup,
    GlFormInput,
  },
  model: {
    prop: 'value',
    event: 'input',
  },
  props: {
    tokenList: {
      type: Array,
      required: true,
    },
    value: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      results: [],
      arrowCounter: -1,
      userDismissedResults: false,
      suggestionsId: uniqueId('token-suggestions-'),
    };
  },
  computed: {
    showAutocomplete() {
      return this.showSuggestions ? 'off' : 'on';
    },
    showSuggestions() {
      return this.results.length > 0;
    },
  },
  mounted() {
    document.addEventListener('click', this.handleClickOutside);
  },
  destroyed() {
    document.removeEventListener('click', this.handleClickOutside);
  },
  methods: {
    closeSuggestions() {
      this.results = [];
      this.arrowCounter = -1;
    },
    handleClickOutside(event) {
      if (!this.$el.contains(event.target)) {
        this.closeSuggestions();
      }
    },
    onArrowDown() {
      const newCount = this.arrowCounter + 1;

      if (newCount >= this.results.length) {
        this.arrowCounter = 0;
        return;
      }

      this.arrowCounter = newCount;
    },
    onArrowUp() {
      const newCount = this.arrowCounter - 1;

      if (newCount < 0) {
        this.arrowCounter = this.results.length - 1;
        return;
      }

      this.arrowCounter = newCount;
    },
    onEnter() {
      const currentToken = this.results[this.arrowCounter] || this.value;
      this.selectToken(currentToken);
    },
    onEsc() {
      if (!this.showSuggestions) {
        this.$emit('input', '');
      }
      this.closeSuggestions();
      this.userDismissedResults = true;
    },
    onEntry(value) {
      this.$emit('input', value);
      this.userDismissedResults = false;

      // short circuit so that we don't false match on empty string
      if (value.length < 1) {
        this.closeSuggestions();
        return;
      }

      const filteredTokens = this.tokenList.filter(token =>
        token.toLowerCase().includes(value.toLowerCase()),
      );

      if (filteredTokens.length) {
        this.openSuggestions(filteredTokens);
      } else {
        this.closeSuggestions();
      }
    },
    openSuggestions(filteredResults) {
      this.results = filteredResults;
    },
    selectToken(value) {
      this.$emit('input', value);
      this.closeSuggestions();
      this.$emit('key-selected');
    },
  },
};
</script>
<template>
  <div>
    <div class="dropdown position-relative" role="combobox" aria-owns="token-suggestions">
      <gl-form-group :label="__('Key')" label-for="ci-variable-key">
        <gl-form-input
          id="ci-variable-key"
          :value="value"
          type="text"
          role="searchbox"
          class="form-control pl-2 js-env-input"
          :autocomplete="showAutocomplete"
          aria-autocomplete="list"
          aria-controls="token-suggestions"
          aria-haspopup="listbox"
          :aria-expanded="showSuggestions"
          data-qa-selector="ci_variable_key_field"
          @input="onEntry"
          @keydown.down="onArrowDown"
          @keydown.up="onArrowUp"
          @keydown.enter.prevent="onEnter"
          @keydown.esc.stop="onEsc"
          @keydown.tab="closeSuggestions"
        />
      </gl-form-group>

      <div
        v-show="showSuggestions && !userDismissedResults"
        id="ci-variable-dropdown"
        class="dropdown-menu dropdown-menu-selectable dropdown-menu-full-width"
        :class="{ 'd-block': showSuggestions }"
      >
        <div class="dropdown-content">
          <ul :id="suggestionsId">
            <li
              v-for="(result, i) in results"
              :key="i"
              role="option"
              :class="{ 'gl-bg-gray-50': i === arrowCounter }"
              :aria-selected="i === arrowCounter"
            >
              <gl-button tabindex="-1" class="btn-transparent pl-2" @click="selectToken(result)">{{
                result
              }}</gl-button>
            </li>
          </ul>
        </div>
      </div>
    </div>
  </div>
</template>
