<script>
import { GlAlert } from '@gitlab/ui';
import { n__ } from '~/locale';
import PackagesListLoader from '~/packages_and_registries/shared/components/packages_list_loader.vue';
import RegistryList from '~/packages_and_registries/shared/components/registry_list.vue';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { makeLoadVersionsErrorMessage } from '~/ml/model_registry/translations';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import getModelVersionsQuery from '../graphql/queries/get_model_versions.query.graphql';
import { GRAPHQL_PAGE_SIZE, MODEL_ENTITIES } from '../constants';
import EmptyState from './empty_state.vue';
import ModelVersionRow from './model_version_row.vue';

export default {
  components: {
    EmptyState,
    GlAlert,
    ModelVersionRow,
    PackagesListLoader,
    RegistryList,
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
        this.errorMessage = makeLoadVersionsErrorMessage(error.message);
        Sentry.captureException(error);
      },
    },
  },
  computed: {
    gid() {
      return convertToGraphQLId('Ml::Model', this.modelId);
    },
    isListEmpty() {
      return this.count === 0;
    },
    isLoading() {
      return this.$apollo.queries.modelVersions.loading;
    },
    pageInfo() {
      return this.modelVersions?.pageInfo ?? {};
    },
    listTitle() {
      return n__('%d version', '%d versions', this.versions.length);
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
    count() {
      return this.modelVersions?.count ?? 0;
    },
  },
  methods: {
    fetchPreviousVersionsPage() {
      const variables = {
        ...this.queryVariables,
        first: null,
        last: GRAPHQL_PAGE_SIZE,
        before: this.pageInfo?.startCursor,
      };
      this.$apollo.queries.modelVersions.fetchMore({
        variables,
        updateQuery: (previousResult, { fetchMoreResult }) => {
          return fetchMoreResult;
        },
      });
    },
    fetchNextVersionsPage() {
      const variables = {
        ...this.queryVariables,
        first: GRAPHQL_PAGE_SIZE,
        last: null,
        after: this.pageInfo?.endCursor,
      };

      this.$apollo.queries.modelVersions.fetchMore({
        variables,
        updateQuery: (previousResult, { fetchMoreResult }) => {
          return fetchMoreResult;
        },
      });
    },
  },
  modelVersionEntity: MODEL_ENTITIES.modelVersion,
};
</script>
<template>
  <div>
    <div v-if="isLoading">
      <packages-list-loader />
    </div>
    <gl-alert v-else-if="errorMessage" variant="danger" :dismissible="false">{{
      errorMessage
    }}</gl-alert>
    <empty-state v-else-if="isListEmpty" :entity-type="$options.modelVersionEntity" />
    <div v-else>
      <registry-list
        :hidden-delete="true"
        :is-loading="isLoading"
        :items="versions"
        :pagination="pageInfo"
        :title="listTitle"
        @prev-page="fetchPreviousVersionsPage"
        @next-page="fetchNextVersionsPage"
      >
        <template #default="{ item }">
          <model-version-row :model-version="item" />
        </template>
      </registry-list>
    </div>
  </div>
</template>
