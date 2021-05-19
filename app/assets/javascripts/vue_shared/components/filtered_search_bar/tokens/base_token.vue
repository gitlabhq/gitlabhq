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
    tokenConfig: {
      type: Object,
      required: true,
    },
    tokenValue: {
      type: Object,
      required: true,
    },
    tokenActive: {
      type: Boolean,
      required: true,
    },
    tokensListLoading: {
      type: Boolean,
      required: true,
    },
    tokenValues: {
      type: Array,
      required: true,
    },
    fnActiveTokenValue: {
      type: Function,
      required: true,
    },
    defaultTokenValues: {
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
      return this.recentTokenValues.map((tokenValue) => tokenValue.id || tokenValue.name);
    },
    currentTokenValue() {
      if (this.fnCurrentTokenValue) {
        return this.fnCurrentTokenValue(this.tokenValue.data);
      }
      return this.tokenValue.data.toLowerCase();
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
            (tokenValue) => !this.recentTokenIds.includes(tokenValue[this.valueIdentifier]),
          );
    },
  },
  watch: {
    tokenActive: {
      immediate: true,
      handler(newValue) {
        if (!newValue && !this.tokenValues.length) {
          this.$emit('fetch-token-values', this.tokenValue.data);
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
      if (this.isRecentTokenValuesEnabled) {
        setTokenValueToRecentlyUsed(this.recentTokenValuesStorageKey, activeTokenValue);
      }
    },
  },
};
</script>

<template>
  <gl-filtered-search-token
    :config="tokenConfig"
    v-bind="{ ...this.$parent.$props, ...this.$parent.$attrs }"
    v-on="this.$parent.$listeners"
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
      <gl-loading-icon v-if="tokensListLoading" />
      <template v-else>
        <slot name="token-values-list" :token-values="availableTokenValues"></slot>
      </template>
    </template>
  </gl-filtered-search-token>
</template>
