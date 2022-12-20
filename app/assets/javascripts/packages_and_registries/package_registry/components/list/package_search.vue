<script>
import { sortableFields } from '~/packages_and_registries/package_registry/utils';
import {
  FILTERED_SEARCH_TERM,
  OPERATORS_IS,
  TOKEN_TITLE_TYPE,
  TOKEN_TYPE_TYPE,
} from '~/vue_shared/components/filtered_search_bar/constants';
import RegistrySearch from '~/vue_shared/components/registry/registry_search.vue';
import UrlSync from '~/vue_shared/components/url_sync.vue';
import { getQueryParams, extractFilterAndSorting } from '~/packages_and_registries/shared/utils';
import { LIST_KEY_CREATED_AT } from '~/packages_and_registries/package_registry/constants';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import PackageTypeToken from './tokens/package_type_token.vue';

export default {
  tokens: [
    {
      type: TOKEN_TYPE_TYPE,
      icon: 'package',
      title: TOKEN_TITLE_TYPE,
      unique: true,
      token: PackageTypeToken,
      operators: OPERATORS_IS,
    },
  ],
  components: { RegistrySearch, UrlSync, LocalStorageSync },
  inject: ['isGroupPage'],
  data() {
    return {
      filters: [],
      sorting: {
        orderBy: LIST_KEY_CREATED_AT,
        sort: 'desc',
      },
      mountRegistrySearch: false,
    };
  },
  computed: {
    sortableFields() {
      return sortableFields(this.isGroupPage);
    },
    parsedSorting() {
      const cleanOrderBy = this.sorting?.orderBy.replace('_at', '');
      return `${cleanOrderBy}_${this.sorting?.sort}`.toUpperCase();
    },
    parsedFilters() {
      const parsed = {
        packageName: '',
        packageType: undefined,
      };

      return this.filters.reduce((acc, filter) => {
        if (filter.type === TOKEN_TYPE_TYPE && filter.value?.data) {
          return {
            ...acc,
            packageType: filter.value.data.toUpperCase(),
          };
        }

        if (filter.type === FILTERED_SEARCH_TERM) {
          return {
            ...acc,
            packageName: `${acc.packageName} ${filter.value.data}`.trim(),
          };
        }

        return acc;
      }, parsed);
    },
  },
  mounted() {
    const queryParams = getQueryParams(window.document.location.search);
    const { sorting, filters } = extractFilterAndSorting(queryParams);
    this.updateSorting(sorting);
    this.updateFilters(filters);
    this.mountRegistrySearch = true;
    this.emitUpdate();
  },
  methods: {
    updateFilters(newValue) {
      this.filters = newValue;
    },
    updateSorting(newValue) {
      this.sorting = { ...this.sorting, ...newValue };
    },
    updateSortingAndEmitUpdate(newValue) {
      this.updateSorting(newValue);
      this.emitUpdate();
    },
    emitUpdate() {
      this.$emit('update', { sort: this.parsedSorting, filters: this.parsedFilters });
    },
  },
};
</script>

<template>
  <local-storage-sync
    storage-key="package_registry_list_sorting"
    :value="sorting"
    @input="updateSorting"
  >
    <url-sync>
      <template #default="{ updateQuery }">
        <registry-search
          v-if="mountRegistrySearch"
          :filters="filters"
          :sorting="sorting"
          :tokens="$options.tokens"
          :sortable-fields="sortableFields"
          @sorting:changed="updateSortingAndEmitUpdate"
          @filter:changed="updateFilters"
          @filter:submit="emitUpdate"
          @query:changed="updateQuery"
        />
      </template>
    </url-sync>
  </local-storage-sync>
</template>
