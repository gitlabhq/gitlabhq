<script>
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { makeLoadVersionsErrorMessage } from '~/ml/model_registry/translations';
import { s__ } from '~/locale';
import getModelVersionsQuery from '../graphql/queries/get_model_versions.query.graphql';
import {
  GRAPHQL_PAGE_SIZE,
  LIST_KEY_CREATED_AT,
  LIST_KEY_VERSION,
  SORT_KEY_CREATED_AT,
  SORT_KEY_ORDER,
} from '../constants';
import SearchableTable from './searchable_table.vue';
import EmptyState from './model_list_empty_state.vue';

export default {
  components: {
    EmptyState,
    SearchableTable,
  },
  inject: ['createModelVersionPath', 'latestVersion'],
  props: {
    modelId: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      modelVersions: {},
      errorMessage: '',
      skipQueries: true,
      queryVariables: {},
    };
  },
  apollo: {
    modelVersions: {
      query: getModelVersionsQuery,
      variables() {
        return this.queryVariables;
      },
      update(data) {
        return data.mlModel?.versions ?? {};
      },
      error(error) {
        this.handleError(error);
      },
      skip() {
        return this.skipQueries;
      },
    },
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.modelVersions.loading;
    },
    pageInfo() {
      return this.modelVersions?.pageInfo ?? {};
    },
    versions() {
      return this.modelVersions?.nodes ?? [];
    },
    showSearch() {
      return Boolean(this.latestVersion);
    },
  },
  methods: {
    fetchPage(variables) {
      this.queryVariables = {
        id: this.modelId,
        first: GRAPHQL_PAGE_SIZE,
        ...variables,
        version: variables.name,
        orderBy: variables.orderBy?.toUpperCase() || SORT_KEY_CREATED_AT,
        sort: variables.sort?.toUpperCase() || SORT_KEY_ORDER,
      };

      this.errorMessage = '';
      this.skipQueries = false;

      this.$apollo.queries.modelVersions.fetchMore({});
    },
    handleError(error) {
      this.errorMessage = makeLoadVersionsErrorMessage(error.message);
      Sentry.captureException(error);
    },
  },
  sortableFields: [
    {
      orderBy: LIST_KEY_VERSION,
      label: s__('MlExperimentTracking|Version'),
    },
    {
      orderBy: LIST_KEY_CREATED_AT,
      label: s__('MlExperimentTracking|Created'),
    },
  ],
  emptyState: {
    title: s__('MlModelRegistry|Manage versions of your machine learning model'),
    description: s__('MlModelRegistry|Use versions to track performance, parameters, and metadata'),
    primaryText: s__('MlModelRegistry|Create model version'),
  },
};
</script>
<template>
  <searchable-table
    :show-search="showSearch"
    :page-info="pageInfo"
    :model-versions="versions"
    :error-message="errorMessage"
    :is-loading="isLoading"
    :sortable-fields="$options.sortableFields"
    @fetch-page="fetchPage"
  >
    <template #empty-state>
      <empty-state
        :title="$options.emptyState.title"
        :description="$options.emptyState.description"
        :primary-text="$options.emptyState.primaryText"
        :primary-link="createModelVersionPath"
      />
    </template>
  </searchable-table>
</template>
