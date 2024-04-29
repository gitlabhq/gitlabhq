<script>
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { makeLoadVersionsErrorMessage } from '~/ml/model_registry/translations';
import { s__ } from '~/locale';
import getModelVersionsQuery from '../graphql/queries/get_model_versions.query.graphql';
import {
  GRAPHQL_PAGE_SIZE,
  LIST_KEY_CREATED_AT,
  LIST_KEY_VERSION,
  MODEL_ENTITIES,
  SORT_KEY_CREATED_AT,
  SORT_KEY_ORDER,
} from '../constants';
import SearchableList from './searchable_list.vue';
import EmptyState from './empty_state.vue';
import ModelVersionRow from './model_version_row.vue';

export default {
  components: {
    EmptyState,
    ModelVersionRow,
    SearchableList,
  },
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
  modelVersionEntity: MODEL_ENTITIES.modelVersion,
  sortableFields: [
    {
      orderBy: LIST_KEY_VERSION,
      label: s__('MlExperimentTracking|Version'),
    },
    {
      orderBy: LIST_KEY_CREATED_AT,
      label: s__('MlExperimentTracking|Created at'),
    },
  ],
};
</script>
<template>
  <searchable-list
    show-search
    :page-info="pageInfo"
    :items="versions"
    :error-message="errorMessage"
    :is-loading="isLoading"
    :sortable-fields="$options.sortableFields"
    @fetch-page="fetchPage"
  >
    <template #empty-state>
      <empty-state :entity-type="$options.modelVersionEntity" />
    </template>

    <template #item="{ item }">
      <model-version-row :model-version="item" />
    </template>
  </searchable-list>
</template>
