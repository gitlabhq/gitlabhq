<script>
import {
  GlFilteredSearchToken,
  GlFilteredSearchSuggestion,
  GlDropdownDivider,
  GlDropdownSectionHeader,
  GlDropdownText,
  GlLoadingIcon,
} from '@gitlab/ui';
import { debounce, last } from 'lodash';

import { stripQuotes } from '~/lib/utils/text_utility';
import {
  DEBOUNCE_DELAY,
  FILTERS_NONE_ANY,
  OPERATOR_NOT,
  OPERATOR_OR,
  OPERATORS_TO_GROUP,
} from '../constants';
import { getRecentlyUsedSuggestions, setTokenValueToRecentlyUsed } from '../filtered_search_utils';

export default {
  components: {
    GlFilteredSearchToken,
    GlFilteredSearchSuggestion,
    GlDropdownDivider,
    GlDropdownSectionHeader,
    GlDropdownText,
    GlLoadingIcon,
  },
  props: {
    config: {
      type: Object,
      required: true,
    },
    value: {
      type: Object,
      required: true,
    },
    active: {
      type: Boolean,
      required: true,
    },
    suggestionsLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
    suggestions: {
      type: Array,
      required: false,
      default: () => [],
    },
    getActiveTokenValue: {
      type: Function,
      required: false,
      default: (suggestions, data) => suggestions.find(({ value }) => value === data),
    },
    defaultSuggestions: {
      type: Array,
      required: false,
      default: () => [],
    },
    preloadedSuggestions: {
      type: Array,
      required: false,
      default: () => [],
    },
    valueIdentifier: {
      type: Function,
      required: false,
      default: (token) => token.id,
    },
    searchBy: {
      type: String,
      required: false,
      default: undefined,
    },
    appliedTokens: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data() {
    return {
      hasFetched: false, // use this to avoid flash of `No suggestions found` before fetching
      searchKey: '',
      selectedTokens: [],
      recentSuggestions: this.config.recentSuggestionsStorageKey
        ? getRecentlyUsedSuggestions(
            this.config.recentSuggestionsStorageKey,
            this.appliedTokens,
            this.valueIdentifier,
          ) ?? []
        : [],
    };
  },
  computed: {
    isRecentSuggestionsEnabled() {
      return Boolean(this.config.recentSuggestionsStorageKey);
    },
    suggestionsEnabled() {
      return !this.config.suggestionsDisabled;
    },
    recentTokenIds() {
      return this.recentSuggestions.map(this.valueIdentifier);
    },
    preloadedTokenIds() {
      return this.preloadedSuggestions.map(this.valueIdentifier);
    },
    activeTokenValue() {
      const data =
        this.multiSelectEnabled && Array.isArray(this.value.data)
          ? last(this.value.data)
          : this.value.data;
      return this.getActiveTokenValue(this.suggestions, data);
    },
    availableDefaultSuggestions() {
      if ([OPERATOR_NOT, OPERATOR_OR].includes(this.value.operator)) {
        return this.defaultSuggestions.filter(
          (suggestion) => !FILTERS_NONE_ANY.includes(suggestion.value),
        );
      }
      return this.defaultSuggestions;
    },
    /**
     * Return all the suggestions when searchKey is present
     * otherwise return only the suggestions which aren't
     * present in "Recently used"
     */
    availableSuggestions() {
      const suggestions = this.searchKey
        ? this.suggestions
        : this.suggestions.filter(
            (tokenValue) =>
              !this.recentTokenIds.includes(this.valueIdentifier(tokenValue)) &&
              !this.preloadedTokenIds.includes(this.valueIdentifier(tokenValue)),
          );

      return this.applyMaxSuggestions(suggestions);
    },
    showDefaultSuggestions() {
      return this.availableDefaultSuggestions.length > 0;
    },
    showNoMatchesText() {
      return this.searchKey && !this.availableSuggestions.length;
    },
    showRecentSuggestions() {
      return (
        this.isRecentSuggestionsEnabled && this.recentSuggestions.length > 0 && !this.searchKey
      );
    },
    showPreloadedSuggestions() {
      return this.preloadedSuggestions.length > 0 && !this.searchKey;
    },
    showAvailableSuggestions() {
      return this.availableSuggestions.length > 0;
    },
    searchTerm() {
      return this.searchBy && this.activeTokenValue
        ? this.activeTokenValue[this.searchBy]
        : undefined;
    },
    multiSelectEnabled() {
      return this.config.multiSelect && OPERATORS_TO_GROUP.includes(this.value.operator);
    },
    validatedConfig() {
      if (this.config.multiSelect && !this.multiSelectEnabled) {
        return {
          ...this.config,
          multiSelect: false,
        };
      }
      return this.config;
    },
  },
  watch: {
    active: {
      immediate: true,
      handler(active) {
        if (!active && !this.suggestions.length) {
          // data could be a string or an array of strings
          const selectedItems = [this.value.data].flat();
          selectedItems.forEach((item) => {
            const search = this.searchTerm ? this.searchTerm : item;
            this.$emit('fetch-suggestions', search);
          });
        }
      },
    },
    suggestionsLoading: {
      handler(loading) {
        if (loading) {
          this.hasFetched = true;
        }
      },
    },
    value: {
      deep: true,
      immediate: true,
      handler(newValue) {
        const { data } = newValue;

        if (!this.multiSelectEnabled) {
          return;
        }

        // don't add empty values to selectedUsernames
        if (!data) {
          return;
        }

        if (Array.isArray(data)) {
          this.selectedTokens = data;
          // !active so we don't add strings while searching, e.g. r, ro, roo
          // !includes so we don't add the same usernames (if @input is emitted twice)
        } else if (!this.active && !this.selectedTokens.includes(data)) {
          this.selectedTokens = this.selectedTokens.concat(data);
        }
      },
    },
  },
  methods: {
    handleInput: debounce(function debouncedSearch({ data, operator }) {
      // in multiSelect mode, data could be an array
      if (Array.isArray(data)) return;

      // Prevent fetching suggestions when data or operator is not present
      if (data || operator) {
        this.searchKey = data;

        if (!this.activeTokenValue) {
          let search = this.searchTerm ? this.searchTerm : data;

          if (search.startsWith('"') && search.endsWith('"')) {
            search = stripQuotes(search);
          } else if (search.startsWith('"')) {
            search = search.slice(1, search.length);
          }

          this.$emit('fetch-suggestions', search);
        }
      }
    }, DEBOUNCE_DELAY),
    handleTokenValueSelected(selectedValue) {
      if (this.multiSelectEnabled) {
        const index = this.selectedTokens.indexOf(selectedValue);
        if (index > -1) {
          this.selectedTokens.splice(index, 1);
        } else {
          this.selectedTokens.push(selectedValue);
        }

        // need to clear search
        this.$emit('input', { ...this.value, data: '' });
      }

      const activeTokenValue = this.getActiveTokenValue(this.suggestions, selectedValue);
      // Make sure that;
      // 1. Recently used values feature is enabled
      // 2. User has actually selected a value
      // 3. Selected value is not part of preloaded list.
      if (
        this.isRecentSuggestionsEnabled &&
        activeTokenValue &&
        !this.preloadedTokenIds.includes(this.valueIdentifier(activeTokenValue))
      ) {
        setTokenValueToRecentlyUsed(this.config.recentSuggestionsStorageKey, activeTokenValue);
      }
    },
    applyMaxSuggestions(suggestions) {
      const { maxSuggestions } = this.config;
      if (!maxSuggestions || maxSuggestions <= 0) return suggestions;

      return suggestions.slice(0, maxSuggestions);
    },
  },
};
</script>

<template>
  <gl-filtered-search-token
    :config="validatedConfig"
    :value="value"
    :active="active"
    :multi-select-values="selectedTokens"
    v-bind="$attrs"
    v-on="$listeners"
    @input="handleInput"
    @select="handleTokenValueSelected"
  >
    <template #view-token="viewTokenProps">
      <slot
        name="view-token"
        :view-token-props="/* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */ {
          ...viewTokenProps,
          activeTokenValue,
          selectedTokens,
        } /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */"
      ></slot>
    </template>
    <template #view="viewTokenProps">
      <slot
        name="view"
        :view-token-props="/* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */ {
          ...viewTokenProps,
          activeTokenValue,
          selectedTokens,
        } /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */"
      ></slot>
    </template>
    <template v-if="suggestionsEnabled" #suggestions>
      <template v-if="showDefaultSuggestions">
        <gl-filtered-search-suggestion
          v-for="token in availableDefaultSuggestions"
          :key="token.value"
          :value="token.value"
        >
          {{ token.text }}
        </gl-filtered-search-suggestion>
        <gl-dropdown-divider />
      </template>
      <template v-if="showRecentSuggestions">
        <gl-dropdown-section-header>{{ __('Recently used') }}</gl-dropdown-section-header>
        <slot
          name="suggestions-list"
          :suggestions="recentSuggestions"
          :selections="selectedTokens"
        ></slot>
        <gl-dropdown-divider />
      </template>
      <slot
        v-if="showPreloadedSuggestions"
        name="suggestions-list"
        :suggestions="preloadedSuggestions"
        :selections="selectedTokens"
      ></slot>
      <gl-loading-icon v-if="suggestionsLoading" size="sm" />
      <template v-else-if="showAvailableSuggestions">
        <slot
          name="suggestions-list"
          :suggestions="availableSuggestions"
          :selections="selectedTokens"
        ></slot>
      </template>
      <gl-dropdown-text v-else-if="showNoMatchesText">
        {{ __('No matches found') }}
      </gl-dropdown-text>
      <gl-dropdown-text v-else-if="hasFetched">{{ __('No suggestions found') }}</gl-dropdown-text>
      <slot name="footer"></slot>
    </template>
  </gl-filtered-search-token>
</template>
