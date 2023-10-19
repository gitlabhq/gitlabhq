<script>
import { queryToObject, setUrlParams, visitUrl } from '~/lib/utils/url_utility';
import { LIST_KEY_CREATED_AT } from '~/ml/experiment_tracking/routes/experiments/show/constants';
import { FILTERED_SEARCH_TERM } from '~/vue_shared/components/filtered_search_bar/constants';
import RegistrySearch from '~/vue_shared/components/registry/registry_search.vue';

export default {
  name: 'SearchBar',
  components: {
    RegistrySearch,
  },
  props: {
    sortableFields: {
      type: Array,
      required: true,
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
  methods: {
    submitFilters() {
      return visitUrl(setUrlParams(this.parsedQuery()));
    },
    parsedQuery() {
      const name = this.filters
        .map((f) => f.value.data)
        .join(' ')
        .trim();

      const filterByQuery = name === '' ? {} : { name };

      return { ...filterByQuery, ...this.sorting };
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
  <registry-search
    :filters="filters"
    :sorting="sorting"
    :sortable-fields="sortableFields"
    @sorting:changed="updateSortingAndEmitUpdate"
    @filter:changed="updateFilters"
    @filter:submit="submitFilters"
    @filter:clear="filters = []"
  />
</template>
