<script>
import RegistrySearch from '~/vue_shared/components/registry/registry_search.vue';
import UrlSync from '~/vue_shared/components/url_sync.vue';
import {
  extractFilterAndSorting,
  extractPageInfo,
  getQueryParams,
} from '~/packages_and_registries/shared/utils';

export default {
  components: { RegistrySearch, UrlSync },
  props: {
    sortableFields: {
      type: Array,
      required: true,
    },
    defaultOrder: {
      type: String,
      required: true,
    },
    defaultSort: {
      type: String,
      required: true,
    },
    tokens: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data() {
    return {
      filters: [],
      sorting: {
        orderBy: this.defaultOrder,
        sort: this.defaultSort,
      },
      pageInfo: {},
      mountRegistrySearch: false,
    };
  },
  computed: {
    parsedSorting() {
      const cleanOrderBy = this.sorting?.orderBy.replace('_at', '');
      return `${cleanOrderBy}_${this.sorting?.sort}`.toUpperCase();
    },
  },
  mounted() {
    this.updateDataFromUrlAndEmitUpdate();
    this.mountRegistrySearch = true;
  },
  methods: {
    updateDataFromUrlAndEmitUpdate() {
      this.updateDataFromUrl();
      this.emitUpdate();
    },
    updateDataFromUrl() {
      const queryParams = getQueryParams(window.location.search);
      const { sorting, filters } = extractFilterAndSorting(queryParams);
      const pageInfo = extractPageInfo(queryParams);
      this.updateSorting(sorting);
      this.updateFilters(filters);
      this.updatePageInfo(pageInfo);
    },
    updateFilters(newValue) {
      this.updatePageInfo({});
      this.filters = newValue;
    },
    updateSorting(newValue) {
      this.updatePageInfo({});
      this.sorting = { ...this.sorting, ...newValue };
    },
    updatePageInfo(newValue) {
      this.pageInfo = newValue;
    },
    updateSortingAndEmitUpdate(newValue) {
      this.updateSorting(newValue);
      this.emitUpdate();
    },
    emitUpdate() {
      this.$emit('update', {
        sort: this.parsedSorting,
        filters: this.filters,
        pageInfo: this.pageInfo,
        sorting: this.sorting,
      });
    },
  },
};
</script>

<template>
  <url-sync @popstate="updateDataFromUrlAndEmitUpdate">
    <template #default="{ updateQuery }">
      <registry-search
        v-if="mountRegistrySearch"
        :filters="filters"
        :sorting="sorting"
        :tokens="tokens"
        :sortable-fields="sortableFields"
        @sorting:changed="updateSortingAndEmitUpdate"
        @filter:changed="updateFilters"
        @filter:submit="emitUpdate"
        @query:changed="updateQuery"
      />
    </template>
  </url-sync>
</template>
