<script>
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { makeLoadVersionsErrorMessage } from '~/ml/model_registry/translations';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import getModelVersionsQuery from '../graphql/queries/get_model_versions.query.graphql';
import { GRAPHQL_PAGE_SIZE, MODEL_ENTITIES } from '../constants';
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
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      modelVersions: {},
      errorMessage: undefined,
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
    },
  },
  computed: {
    gid() {
      return convertToGraphQLId('Ml::Model', this.modelId);
    },
    isLoading() {
      return this.$apollo.queries.modelVersions.loading;
    },
    pageInfo() {
      return this.modelVersions?.pageInfo ?? {};
    },
    queryVariables() {
      return {
        id: this.gid,
        first: GRAPHQL_PAGE_SIZE,
      };
    },
    versions() {
      return this.modelVersions?.nodes ?? [];
    },
  },
  methods: {
    fetchPage(pageInfo) {
      const variables = {
        ...this.queryVariables,
        ...pageInfo,
      };

      this.$apollo.queries.modelVersions
        .fetchMore({
          variables,
          updateQuery: (previousResult, { fetchMoreResult }) => {
            return fetchMoreResult;
          },
        })
        .catch(this.handleError);
    },
    handleError(error) {
      this.errorMessage = makeLoadVersionsErrorMessage(error.message);
      Sentry.captureException(error);
    },
  },
  modelVersionEntity: MODEL_ENTITIES.modelVersion,
};
</script>
<template>
  <searchable-list
    :page-info="pageInfo"
    :items="versions"
    :error-message="errorMessage"
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
