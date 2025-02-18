<script>
import { GlKeysetPagination, GlTooltip } from '@gitlab/ui';
import RegistrySearch from '~/vue_shared/components/registry/registry_search.vue';
import { GRAPHQL_PAGE_SIZE, LIST_KEY_CREATED_AT } from '~/ml/model_registry/constants';
import { queryToObject, setUrlParams, updateHistory } from '~/lib/utils/url_utility';
import { FILTERED_SEARCH_TERM } from '~/vue_shared/components/filtered_search_bar/constants';
import LoadOrErrorOrShow from '~/ml/model_registry/components/load_or_error_or_show.vue';
import ModelsTable from '~/ml/model_registry/components/models_table.vue';
import ModelVersionsTable from '~/ml/model_registry/components/model_versions_table.vue';
import CandidatesTable from '~/ml/model_registry/components/candidates_table.vue';

export default {
  name: 'SearchableTable',
  components: {
    RegistrySearch,
    LoadOrErrorOrShow,
    GlKeysetPagination,
    ModelsTable,
    ModelVersionsTable,
    CandidatesTable,
  },
  directives: {
    GlTooltip,
  },
  props: {
    modelVersions: {
      type: Array,
      required: false,
      default: () => [],
    },
    models: {
      type: Array,
      required: false,
      default: () => [],
    },
    candidates: {
      type: Array,
      required: false,
      default: () => [],
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
      class="mt-2"
      @sorting:changed="updateSortingAndEmitUpdate"
      @filter:changed="updateFilters"
      @filter:submit="submitFilters"
      @filter:clear="filters = []"
    />
    <load-or-error-or-show :is-loading="isLoading" :error-message="errorMessage">
      <model-versions-table
        v-if="modelVersions.length"
        :items="modelVersions"
        @model-versions-update="submitFilters"
      />
      <models-table v-else-if="models.length" :items="models" @models-update="submitFilters" />
      <candidates-table v-else-if="candidates.length" :items="candidates" />
      <slot v-else name="empty-state"></slot>
      <gl-keyset-pagination
        v-if="pageInfo.hasPreviousPage || pageInfo.hasNextPage"
        v-bind="pageInfo"
        class="gl-mt-3 gl-self-center"
        @prev="prevPage"
        @next="nextPage"
      />
    </load-or-error-or-show>
  </div>
</template>
