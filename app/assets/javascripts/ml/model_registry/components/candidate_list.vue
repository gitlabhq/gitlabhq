<script>
import { GlAlert } from '@gitlab/ui';
import { n__ } from '~/locale';
import PackagesListLoader from '~/packages_and_registries/shared/components/packages_list_loader.vue';
import RegistryList from '~/packages_and_registries/shared/components/registry_list.vue';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import CandidateListRow from '~/ml/model_registry/components/candidate_list_row.vue';
import { makeLoadCandidatesErrorMessage, NO_CANDIDATES_LABEL } from '../translations';
import getModelCandidatesQuery from '../graphql/queries/get_model_candidates.query.graphql';
import { GRAPHQL_PAGE_SIZE } from '../constants';

export default {
  name: 'MlCandidateList',
  components: {
    GlAlert,
    CandidateListRow,
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
    candidates: {
      query: getModelCandidatesQuery,
      variables() {
        return this.queryVariables;
      },
      update(data) {
        return data.mlModel?.candidates ?? {};
      },
      error(error) {
        this.errorMessage = makeLoadCandidatesErrorMessage(error.message);
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
      return this.$apollo.queries.candidates.loading;
    },
    pageInfo() {
      return this.candidates?.pageInfo ?? {};
    },
    listTitle() {
      return n__('%d candidate', '%d candidates', this.count);
    },
    queryVariables() {
      return {
        id: this.gid,
        first: GRAPHQL_PAGE_SIZE,
      };
    },
    items() {
      return this.candidates?.nodes ?? [];
    },
    count() {
      return this.candidates?.count ?? 0;
    },
  },
  methods: {
    fetchPage({ first = null, last = null, before = null, after = null } = {}) {
      const variables = {
        ...this.queryVariables,
        first,
        last,
        before,
        after,
      };

      this.$apollo.queries.candidates.fetchMore({
        variables,
        updateQuery: (previousResult, { fetchMoreResult }) => {
          return fetchMoreResult;
        },
      });
    },
    fetchPreviousCandidatesPage() {
      this.fetchPage({
        last: GRAPHQL_PAGE_SIZE,
        before: this.pageInfo?.startCursor,
      });
    },
    fetchNextCandidatesPage() {
      this.fetchPage({
        first: GRAPHQL_PAGE_SIZE,
        after: this.pageInfo?.endCursor,
      });
    },
  },
  i18n: {
    NO_CANDIDATES_LABEL,
  },
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
    <div v-else-if="isListEmpty" class="gl-text-secondary">
      {{ $options.i18n.NO_CANDIDATES_LABEL }}
    </div>
    <div v-else>
      <registry-list
        :hidden-delete="true"
        :is-loading="isLoading"
        :items="items"
        :pagination="pageInfo"
        :title="listTitle"
        @prev-page="fetchPreviousCandidatesPage"
        @next-page="fetchNextCandidatesPage"
      >
        <template #default="{ item }">
          <candidate-list-row :candidate="item" />
        </template>
      </registry-list>
    </div>
  </div>
</template>
