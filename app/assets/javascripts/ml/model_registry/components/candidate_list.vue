<script>
import * as Sentry from '~/sentry/sentry_browser_wrapper';
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
      type: String,
      required: true,
    },
  },
  data() {
    return {
      candidates: {},
      errorMessage: '',
      skipQueries: true,
      queryVariables: undefined,
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
      skip() {
        return !this.queryVariables;
      },
    },
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.candidates.loading;
    },
    pageInfo() {
      return this.candidates?.pageInfo ?? {};
    },
    items() {
      return this.candidates?.nodes ?? [];
    },
  },
  methods: {
    fetchPage(variables) {
      this.errorMessage = '';
      this.queryVariables = {
        id: this.modelId,
        first: GRAPHQL_PAGE_SIZE,
        ...variables,
      };
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
      :is-loading="isLoading"
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
