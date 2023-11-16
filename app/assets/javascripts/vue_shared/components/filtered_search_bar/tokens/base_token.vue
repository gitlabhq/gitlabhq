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
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
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
  mixins: [glFeatureFlagMixin()],
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
      type: String,
      required: false,
      default: 'id',
    },
    searchBy: {
      type: String,
      required: false,
      default: undefined,
    },
    multiSelectValues: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data() {
    return {
      hasFetched: false, // use this to avoid flash of `No suggestions found` before fetching
      searchKey: '',
      recentSuggestions: this.config.recentSuggestionsStorageKey
        ? getRecentlyUsedSuggestions(this.config.recentSuggestionsStorageKey) ?? []
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
      return this.recentSuggestions.map((tokenValue) => tokenValue[this.valueIdentifier]);
    },
    preloadedTokenIds() {
      return this.preloadedSuggestions.map((tokenValue) => tokenValue[this.valueIdentifier]);
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
              !this.recentTokenIds.includes(tokenValue[this.valueIdentifier]) &&
              !this.preloadedTokenIds.includes(tokenValue[this.valueIdentifier]),
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
      return (
        this.config.multiSelect &&
        this.glFeatures.groupMultiSelectTokens &&
        OPERATORS_TO_GROUP.includes(this.value.operator)
      );
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
        this.$emit('token-selected', selectedValue);
      }

      const activeTokenValue = this.getActiveTokenValue(this.suggestions, selectedValue);
      // Make sure that;
      // 1. Recently used values feature is enabled
      // 2. User has actually selected a value
      // 3. Selected value is not part of preloaded list.
      if (
        this.isRecentSuggestionsEnabled &&
        activeTokenValue &&
        !this.preloadedTokenIds.includes(activeTokenValue[this.valueIdentifier])
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
    :multi-select-values="multiSelectValues"
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
        } /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */"
      ></slot>
    </template>
    <template #view="viewTokenProps">
      <slot
        name="view"
        :view-token-props="/* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */ {
          ...viewTokenProps,
          activeTokenValue,
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
        <slot name="suggestions-list" :suggestions="recentSuggestions"></slot>
        <gl-dropdown-divider />
      </template>
      <slot
        v-if="showPreloadedSuggestions"
        name="suggestions-list"
        :suggestions="preloadedSuggestions"
      ></slot>
      <gl-loading-icon v-if="suggestionsLoading" size="sm" />
      <template v-else-if="showAvailableSuggestions">
        <slot name="suggestions-list" :suggestions="availableSuggestions"></slot>
      </template>
      <gl-dropdown-text v-else-if="showNoMatchesText">
        {{ __('No matches found') }}
      </gl-dropdown-text>
      <gl-dropdown-text v-else-if="hasFetched">{{ __('No suggestions found') }}</gl-dropdown-text>
      <slot name="footer"></slot>
    </template>
  </gl-filtered-search-token>
</template>
