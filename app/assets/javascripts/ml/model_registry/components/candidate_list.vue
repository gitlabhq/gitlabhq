<script>
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { makeLoadCandidatesErrorMessage, NO_CANDIDATES_LABEL } from '../translations';
import getModelCandidatesQuery from '../graphql/queries/get_model_candidates.query.graphql';
import { GRAPHQL_PAGE_SIZE } from '../constants';
import SearchableList from './searchable_list.vue';
import CandidateListRow from './candidate_list_row.vue';

export default {
  name: 'MlCandidateList',
  components: {
    CandidateListRow,
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
      candidates: {},
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
        this.handleError(error);
      },
    },
  },
  computed: {
    gid() {
      return convertToGraphQLId('Ml::Model', this.modelId);
    },
    isLoading() {
      return this.$apollo.queries.candidates.loading;
    },
    pageInfo() {
      return this.candidates?.pageInfo ?? {};
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
  },
  methods: {
    fetchPage(newPageInfo) {
      const variables = {
        ...this.queryVariables,
        ...newPageInfo,
      };

      this.$apollo.queries.candidates
        .fetchMore({
          variables,
          updateQuery: (previousResult, { fetchMoreResult }) => {
            return fetchMoreResult;
          },
        })
        .catch(this.handleError);
    },
    handleError(error) {
      this.errorMessage = makeLoadCandidatesErrorMessage(error.message);
      Sentry.captureException(error);
    },
  },
  i18n: {
    NO_CANDIDATES_LABEL,
  },
};
</script>
<template>
  <div>
    <searchable-list
      :page-info="pageInfo"
      :items="items"
      :error-message="errorMessage"
      @fetch-page="fetchPage"
    >
      <template #empty-state>
        {{ $options.i18n.NO_CANDIDATES_LABEL }}
      </template>

      <template #item="{ item }">
        <candidate-list-row :candidate="item" />
      </template>
    </searchable-list>
  </div>
</template>
