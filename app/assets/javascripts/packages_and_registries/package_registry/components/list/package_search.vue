<script>
import { GlFilteredSearchToken } from '@gitlab/ui';
import { sortableFields } from '~/packages_and_registries/package_registry/utils';
import {
  FILTERED_SEARCH_TERM,
  OPERATORS_IS,
  TOKEN_TITLE_TYPE,
  TOKEN_TYPE_TYPE,
  TOKEN_TITLE_VERSION,
  TOKEN_TYPE_VERSION,
  TOKEN_TITLE_STATUS,
  TOKEN_TYPE_STATUS,
} from '~/vue_shared/components/filtered_search_bar/constants';
import PersistedSearch from '~/packages_and_registries/shared/components/persisted_search.vue';
import {
  LIST_KEY_CREATED_AT,
  PACKAGE_STATUS_OPTIONS,
  PACKAGE_TYPES_OPTIONS,
} from '~/packages_and_registries/package_registry/constants';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';

export default {
  tokens: [
    {
      type: TOKEN_TYPE_STATUS,
      icon: 'status',
      title: TOKEN_TITLE_STATUS,
      unique: true,
      token: GlFilteredSearchToken,
      operators: OPERATORS_IS,
      options: PACKAGE_STATUS_OPTIONS,
    },
    {
      type: TOKEN_TYPE_TYPE,
      icon: 'package',
      title: TOKEN_TITLE_TYPE,
      unique: true,
      token: GlFilteredSearchToken,
      operators: OPERATORS_IS,
      options: PACKAGE_TYPES_OPTIONS,
    },
    {
      type: TOKEN_TYPE_VERSION,
      icon: 'doc-versions',
      title: TOKEN_TITLE_VERSION,
      unique: true,
      token: GlFilteredSearchToken,
      operators: OPERATORS_IS,
    },
  ],
  components: {
    LocalStorageSync,
    PersistedSearch,
  },
  inject: ['isGroupPage'],
  data() {
    return {
      sorting: {
        orderBy: LIST_KEY_CREATED_AT,
        sort: 'desc',
      },
      mountRegistrySearch: false,
    };
  },
  computed: {
    localStorageKey() {
      return this.isGroupPage
        ? 'group_package_registry_list_sorting'
        : 'package_registry_list_sorting';
    },
    sortableFields() {
      return sortableFields(this.isGroupPage);
    },
  },
  mounted() {
    // local-storage-sync does not emit `input`
    // event when key is not found, so set the
    // flag if it hasn't been updated
    this.$nextTick(() => {
      if (!this.mountRegistrySearch) {
        this.mountRegistrySearch = true;
      }
    });
  },
  methods: {
    formatFilters(filters) {
      return filters
        .filter((filter) => filter.value?.data)
        .reduce((acc, filter) => {
          if (filter.type === TOKEN_TYPE_TYPE) {
            return {
              ...acc,
              packageType: filter.value.data.toUpperCase(),
            };
          }

          if (filter.type === TOKEN_TYPE_VERSION) {
            return {
              ...acc,
              packageVersion: filter.value.data.trim(),
            };
          }

          if (filter.type === TOKEN_TYPE_STATUS) {
            return {
              ...acc,
              packageStatus: filter.value.data.toUpperCase(),
            };
          }

          if (filter.type === FILTERED_SEARCH_TERM) {
            return {
              ...acc,
              packageName: filter.value.data.trim(),
            };
          }

          return acc;
        }, {});
    },
    updateSorting(newValue) {
      this.sorting = { ...this.sorting, ...newValue };
    },
    updateSortingFromLocalStorage(newValue) {
      this.updateSorting(newValue);
      this.mountRegistrySearch = true;
    },
    emitUpdate(values) {
      const { filters, sorting } = values;
      this.updateSorting(sorting);
      this.$emit('update', { ...values, filters: this.formatFilters(filters) });
    },
  },
};
</script>

<template>
  <local-storage-sync
    :storage-key="localStorageKey"
    :value="sorting"
    @input="updateSortingFromLocalStorage"
  >
    <persisted-search
      v-if="mountRegistrySearch"
      :sortable-fields="sortableFields"
      :default-order="sorting.orderBy"
      :default-sort="sorting.sort"
      :tokens="$options.tokens"
      @update="emitUpdate"
    />
  </local-storage-sync>
</template>
