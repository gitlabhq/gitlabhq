<script>
import {
  GlFilteredSearchToken,
  GlFilteredSearchSuggestion,
  GlDropdownDivider,
  GlDropdownSectionHeader,
  GlLoadingIcon,
} from '@gitlab/ui';
import { debounce } from 'lodash';

import { DEBOUNCE_DELAY } from '../constants';
import { getRecentlyUsedSuggestions, setTokenValueToRecentlyUsed } from '../filtered_search_utils';

export default {
  components: {
    GlFilteredSearchToken,
    GlFilteredSearchSuggestion,
    GlDropdownDivider,
    GlDropdownSectionHeader,
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
    fnActiveTokenValue: {
      type: Function,
      required: false,
      default: (suggestions, currentTokenValue) => {
        return suggestions.find(({ value }) => value === currentTokenValue);
      },
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
    recentSuggestionsStorageKey: {
      type: String,
      required: false,
      default: '',
    },
    valueIdentifier: {
      type: String,
      required: false,
      default: 'id',
    },
    fnCurrentTokenValue: {
      type: Function,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      searchKey: '',
      recentSuggestions: this.recentSuggestionsStorageKey
        ? getRecentlyUsedSuggestions(this.recentSuggestionsStorageKey)
        : [],
      loading: false,
    };
  },
  computed: {
    isRecentSuggestionsEnabled() {
      return Boolean(this.recentSuggestionsStorageKey);
    },
    recentTokenIds() {
      return this.recentSuggestions.map((tokenValue) => tokenValue[this.valueIdentifier]);
    },
    preloadedTokenIds() {
      return this.preloadedSuggestions.map((tokenValue) => tokenValue[this.valueIdentifier]);
    },
    currentTokenValue() {
      if (this.fnCurrentTokenValue) {
        return this.fnCurrentTokenValue(this.value.data);
      }
      return this.value.data.toLowerCase();
    },
    activeTokenValue() {
      return this.fnActiveTokenValue(this.suggestions, this.currentTokenValue);
    },
    /**
     * Return all the suggestions when searchKey is present
     * otherwise return only the suggestions which aren't
     * present in "Recently used"
     */
    availableSuggestions() {
      return this.searchKey
        ? this.suggestions
        : this.suggestions.filter(
            (tokenValue) =>
              !this.recentTokenIds.includes(tokenValue[this.valueIdentifier]) &&
              !this.preloadedTokenIds.includes(tokenValue[this.valueIdentifier]),
          );
    },
  },
  watch: {
    active: {
      immediate: true,
      handler(newValue) {
        if (!newValue && !this.suggestions.length) {
          this.$emit('fetch-suggestions', this.value.data);
        }
      },
    },
  },
  methods: {
    handleInput: debounce(function debouncedSearch({ data }) {
      this.searchKey = data;
      if (!this.suggestionsLoading) {
        this.$emit('fetch-suggestions', data);
      }
    }, DEBOUNCE_DELAY),
    handleTokenValueSelected(activeTokenValue) {
      // Make sure that;
      // 1. Recently used values feature is enabled
      // 2. User has actually selected a value
      // 3. Selected value is not part of preloaded list.
      if (
        this.isRecentSuggestionsEnabled &&
        activeTokenValue &&
        !this.preloadedTokenIds.includes(activeTokenValue[this.valueIdentifier])
      ) {
        setTokenValueToRecentlyUsed(this.recentSuggestionsStorageKey, activeTokenValue);
      }
    },
  },
};
</script>

<template>
  <gl-filtered-search-token
    :config="config"
    :value="value"
    :active="active"
    v-bind="$attrs"
    v-on="$listeners"
    @input="handleInput"
    @select="handleTokenValueSelected(activeTokenValue)"
  >
    <template #view-token="viewTokenProps">
      <slot name="view-token" :view-token-props="{ ...viewTokenProps, activeTokenValue }"></slot>
    </template>
    <template #view="viewTokenProps">
      <slot name="view" :view-token-props="{ ...viewTokenProps, activeTokenValue }"></slot>
    </template>
    <template #suggestions>
      <template v-if="defaultSuggestions.length">
        <gl-filtered-search-suggestion
          v-for="token in defaultSuggestions"
          :key="token.value"
          :value="token.value"
        >
          {{ token.text }}
        </gl-filtered-search-suggestion>
        <gl-dropdown-divider />
      </template>
      <template v-if="isRecentSuggestionsEnabled && recentSuggestions.length && !searchKey">
        <gl-dropdown-section-header>{{ __('Recently used') }}</gl-dropdown-section-header>
        <slot name="suggestions-list" :suggestions="recentSuggestions"></slot>
        <gl-dropdown-divider />
      </template>
      <slot
        v-if="preloadedSuggestions.length && !searchKey"
        name="suggestions-list"
        :suggestions="preloadedSuggestions"
      ></slot>
      <gl-loading-icon v-if="suggestionsLoading" />
      <template v-else>
        <slot name="suggestions-list" :suggestions="availableSuggestions"></slot>
      </template>
    </template>
  </gl-filtered-search-token>
</template>
