<script>
import RegistryList from '~/packages_and_registries/shared/components/registry_list.vue';
import RegistrySearch from '~/vue_shared/components/registry/registry_search.vue';
import { GRAPHQL_PAGE_SIZE, LIST_KEY_CREATED_AT } from '~/ml/model_registry/constants';
import { queryToObject, setUrlParams, updateHistory } from '~/lib/utils/url_utility';
import { FILTERED_SEARCH_TERM } from '~/vue_shared/components/filtered_search_bar/constants';
import LoadOrErrorOrShow from '~/ml/model_registry/components/load_or_error_or_show.vue';

export default {
  name: 'SearchableList',
  components: { RegistryList, RegistrySearch, LoadOrErrorOrShow },
  props: {
    items: {
      type: Array,
      required: true,
    },
    pageInfo: {
      type: Object,
      required: true,
    },
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
    errorMessage: {
      type: String,
      required: false,
      default: '',
    },
    showSearch: {
      type: Boolean,
      required: false,
      default: false,
    },
    sortableFields: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data() {
    const query = queryToObject(window.location.search);

    const filter = query.name ? [{ value: { data: query.name }, type: FILTERED_SEARCH_TERM }] : [];

    const orderBy = query.orderBy || LIST_KEY_CREATED_AT;

    return {
      filters: filter,
      sorting: {
        orderBy,
        sort: (query.sort || 'desc').toLowerCase(),
      },
    };
  },
  computed: {
    isListEmpty() {
      return this.items.length === 0;
    },
    parsedQuery() {
      const name = this.filters
        .map((f) => f.value.data)
        .join(' ')
        .trim();

      const filterByQuery = name === '' ? {} : { name };

      return { ...filterByQuery, ...this.sorting };
    },
  },
  created() {
    this.nextPage();
  },
  methods: {
    prevPage() {
      const variables = {
        first: null,
        last: GRAPHQL_PAGE_SIZE,
        before: this.pageInfo.startCursor,
        ...this.parsedQuery,
      };

      this.fetchPage(variables);
    },
    nextPage() {
      const variables = {
        first: GRAPHQL_PAGE_SIZE,
        last: null,
        after: this.pageInfo.endCursor,
        ...this.parsedQuery,
      };

      this.fetchPage(variables);
    },
    fetchPage(variables) {
      updateHistory({
        url: setUrlParams(variables, window.location.href, true),
        title: document.title,
        replace: true,
      });

      this.$emit('fetch-page', variables);
    },
    submitFilters() {
      this.fetchPage(this.parsedQuery);
    },
    updateFilters(newValue) {
      this.filters = newValue;
    },
    updateSorting(newValue) {
      this.sorting = { ...this.sorting, ...newValue };
    },
    updateSortingAndEmitUpdate(newValue) {
      this.updateSorting(newValue);
      this.submitFilters();
    },
  },
};
</script>

<template>
  <div>
    <registry-search
      v-if="showSearch"
      :filters="filters"
      :sorting="sorting"
      :sortable-fields="sortableFields"
      @sorting:changed="updateSortingAndEmitUpdate"
      @filter:changed="updateFilters"
      @filter:submit="submitFilters"
      @filter:clear="filters = []"
    />
    <load-or-error-or-show :is-loading="isLoading" :error-message="errorMessage">
      <slot v-if="isListEmpty" name="empty-state"></slot>
      <registry-list
        v-else
        :hidden-delete="true"
        :is-loading="isLoading"
        :items="items"
        :pagination="pageInfo"
        @prev-page="prevPage"
        @next-page="nextPage"
      >
        <template #default="{ item }">
          <slot name="item" :item="item"></slot>
        </template>
      </registry-list>
    </load-or-error-or-show>
  </div>
</template>
