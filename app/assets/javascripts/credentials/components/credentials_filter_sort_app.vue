<script>
import { GlFilteredSearch, GlSorting } from '@gitlab/ui';
import { setUrlParams, visitUrl } from '~/lib/utils/url_utility';
import { TOKENS, SORT_OPTIONS } from '../constants';
import { initializeValuesFromQuery, buildSortedUrl } from '../utils';

export default {
  components: {
    GlFilteredSearch,
    GlSorting,
  },
  data() {
    const { tokens, sorting } = initializeValuesFromQuery();
    return {
      tokens,
      sorting,
    };
  },
  computed: {
    availableTokens() {
      // Once SSH or GPG key is selected, discard the rest of the tokens
      if (this.hasKey) {
        return TOKENS.filter(({ type }) => type === 'filter');
      }

      return TOKENS;
    },
    hasKey() {
      return this.tokens.some(
        ({ type, value }) => type === 'filter' && ['ssh_keys', 'gpg_keys'].includes(value.data),
      );
    },
  },
  methods: {
    change() {
      // Once SSH or GPG key is selected, discard the rest of the tokens
      if (this.hasKey) {
        this.tokens = this.tokens.filter(({ type }) => type === 'filter');
      }
    },
    search(tokens) {
      const newParams = {};

      tokens?.forEach((token) => {
        if (typeof token === 'string') {
          newParams.search = token;
        } else if (['created', 'expires', 'last_used'].includes(token.type)) {
          const isBefore = token.value.operator === '<';
          const key = `${token.type}${isBefore ? '_before' : '_after'}`;
          newParams[key] = token.value.data;
        } else {
          newParams[token.type] = token.value.data;
        }
      });
      const newUrl = setUrlParams(newParams, window.location.href, true);
      visitUrl(newUrl);
    },
    handleSortChange(value) {
      visitUrl(buildSortedUrl(value, this.sorting.isAsc));
    },
    handleSortDirectionChange(isAsc) {
      visitUrl(buildSortedUrl(this.sorting.value, isAsc));
    },
  },
  SORT_OPTIONS,
};
</script>

<template>
  <div class="gl-flex gl-flex-col gl-gap-3 md:gl-flex-row">
    <gl-filtered-search
      v-model="tokens"
      :placeholder="s__('CredentialsInventory|Search or filter credentials...')"
      :available-tokens="availableTokens"
      terms-as-tokens
      @submit="search"
      @input="change"
    />
    <gl-sorting
      v-if="!hasKey"
      block
      dropdown-class="gl-w-full"
      :is-ascending="sorting.isAsc"
      :sort-by="sorting.value"
      :sort-options="$options.SORT_OPTIONS"
      @sortByChange="handleSortChange"
      @sortDirectionChange="handleSortDirectionChange"
    />
  </div>
</template>
