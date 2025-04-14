<script>
import { GlFilteredSearch, GlSorting } from '@gitlab/ui';
import { SORT_OPTIONS, FILTER_OPTIONS_CREDENTIALS_INVENTORY } from '~/access_tokens/constants';
import { initializeValuesFromQuery, goTo } from '../utils';

export default {
  components: {
    GlFilteredSearch,
    GlSorting,
  },
  data() {
    const { sorting, tokens } = initializeValuesFromQuery();
    return {
      sorting,
      tokens,
    };
  },
  computed: {
    availableTokens() {
      // Once SSH or GPG key is selected, discard the rest of the tokens
      if (this.hasKey) {
        return FILTER_OPTIONS_CREDENTIALS_INVENTORY.filter(({ type }) => type === 'filter');
      }

      return FILTER_OPTIONS_CREDENTIALS_INVENTORY;
    },
    hasKey() {
      return this.tokens.some(
        ({ type, value }) => type === 'filter' && ['ssh_keys', 'gpg_keys'].includes(value.data),
      );
    },
  },
  methods: {
    change(tokens) {
      this.tokens = tokens;

      // Once SSH or GPG key is selected, discard the rest of the tokens
      if (this.hasKey) {
        this.tokens = this.tokens.filter(({ type }) => type === 'filter');
      }
    },
    search(tokens) {
      goTo(this.sorting.value, this.sorting.isAsc, tokens);
    },
    handleSortChange(sortValue) {
      goTo(sortValue, this.sorting.isAsc, this.tokens);
    },
    handleSortDirectionChange(sortIsAsc) {
      goTo(this.sorting.value, sortIsAsc, this.tokens);
    },
  },
  SORT_OPTIONS,
};
</script>

<template>
  <div class="gl-flex gl-flex-col gl-gap-3 md:gl-flex-row">
    <gl-filtered-search
      class="gl-min-w-0 gl-grow"
      :value="tokens"
      :placeholder="s__('CredentialsInventory|Search or filter credentials…')"
      :available-tokens="availableTokens"
      terms-as-tokens
      @submit="search"
      @input="change"
    />
    <gl-sorting
      v-if="!hasKey"
      block
      dropdown-class="gl-w-full !gl-flex"
      :is-ascending="sorting.isAsc"
      :sort-by="sorting.value"
      :sort-options="$options.SORT_OPTIONS"
      @sortByChange="handleSortChange"
      @sortDirectionChange="handleSortDirectionChange"
    />
  </div>
</template>
