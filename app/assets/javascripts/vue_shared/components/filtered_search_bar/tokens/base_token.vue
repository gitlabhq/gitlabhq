<script>
import {
  GlFilteredSearchToken,
  GlFilteredSearchSuggestion,
  GlDropdownDivider,
  GlDropdownSectionHeader,
  GlLoadingIcon,
} from '@gitlab/ui';

import { DEBOUNCE_DELAY } from '../constants';
import { getRecentlyUsedTokenValues, setTokenValueToRecentlyUsed } from '../filtered_search_utils';

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
    tokensListLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
    tokenValues: {
      type: Array,
      required: false,
      default: () => [],
    },
    fnActiveTokenValue: {
      type: Function,
      required: false,
      default: (tokenValues, currentTokenValue) => {
        return tokenValues.find(({ value }) => value === currentTokenValue);
      },
    },
    defaultTokenValues: {
      type: Array,
      required: false,
      default: () => [],
    },
    preloadedTokenValues: {
      type: Array,
      required: false,
      default: () => [],
    },
    recentTokenValuesStorageKey: {
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
      recentTokenValues: this.recentTokenValuesStorageKey
        ? getRecentlyUsedTokenValues(this.recentTokenValuesStorageKey)
        : [],
      loading: false,
    };
  },
  computed: {
    isRecentTokenValuesEnabled() {
      return Boolean(this.recentTokenValuesStorageKey);
    },
    recentTokenIds() {
      return this.recentTokenValues.map((tokenValue) => tokenValue[this.valueIdentifier]);
    },
    preloadedTokenIds() {
      return this.preloadedTokenValues.map((tokenValue) => tokenValue[this.valueIdentifier]);
    },
    currentTokenValue() {
      if (this.fnCurrentTokenValue) {
        return this.fnCurrentTokenValue(this.value.data);
      }
      return this.value.data.toLowerCase();
    },
    activeTokenValue() {
      return this.fnActiveTokenValue(this.tokenValues, this.currentTokenValue);
    },
    /**
     * Return all the tokenValues when searchKey is present
     * otherwise return only the tokenValues which aren't
     * present in "Recently used"
     */
    availableTokenValues() {
      return this.searchKey
        ? this.tokenValues
        : this.tokenValues.filter(
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
        if (!newValue && !this.tokenValues.length) {
          this.$emit('fetch-token-values', this.value.data);
        }
      },
    },
  },
  methods: {
    handleInput({ data }) {
      this.searchKey = data;
      setTimeout(() => {
        if (!this.tokensListLoading) this.$emit('fetch-token-values', data);
      }, DEBOUNCE_DELAY);
    },
    handleTokenValueSelected(activeTokenValue) {
      // Make sure that;
      // 1. Recently used values feature is enabled
      // 2. User has actually selected a value
      // 3. Selected value is not part of preloaded list.
      if (
        this.isRecentTokenValuesEnabled &&
        activeTokenValue &&
        !this.preloadedTokenIds.includes(activeTokenValue[this.valueIdentifier])
      ) {
        setTokenValueToRecentlyUsed(this.recentTokenValuesStorageKey, activeTokenValue);
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
      <template v-if="defaultTokenValues.length">
        <gl-filtered-search-suggestion
          v-for="token in defaultTokenValues"
          :key="token.value"
          :value="token.value"
        >
          {{ token.text }}
        </gl-filtered-search-suggestion>
        <gl-dropdown-divider />
      </template>
      <template v-if="isRecentTokenValuesEnabled && recentTokenValues.length && !searchKey">
        <gl-dropdown-section-header>{{ __('Recently used') }}</gl-dropdown-section-header>
        <slot name="token-values-list" :token-values="recentTokenValues"></slot>
        <gl-dropdown-divider />
      </template>
      <slot
        v-if="preloadedTokenValues.length"
        name="token-values-list"
        :token-values="preloadedTokenValues"
      ></slot>
      <gl-loading-icon v-if="tokensListLoading" />
      <template v-else>
        <slot name="token-values-list" :token-values="availableTokenValues"></slot>
      </template>
    </template>
  </gl-filtered-search-token>
</template>
