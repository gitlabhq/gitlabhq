<script>
import { GlEmptyState, GlButton } from '@gitlab/ui';
import emptySvgUrl from '@gitlab/svgs/dist/illustrations/status/status-new-md.svg';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { s__, __ } from '~/locale';
import { makeLoadCandidatesErrorMessage, NO_CANDIDATES_LABEL } from '../translations';
import getModelCandidatesQuery from '../graphql/queries/get_model_candidates.query.graphql';
import { GRAPHQL_PAGE_SIZE, CANDIDATES_DOCS_PATH } from '../constants';
import SearchableTable from './searchable_table.vue';

export default {
  name: 'MlCandidateList',
  components: {
    SearchableTable,
    GlButton,
    GlEmptyState,
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
    learnMore: __('Learn more'),
    emptyStateLabel: s__('MlModelRegistry|No runs associated with this model'),
    emptyStateDescription: s__(
      'MlModelRegistry|Use runs to track performance, parameters, and metadata',
    ),
  },
  emptySvgPath: emptySvgUrl,
  CANDIDATES_DOCS_PATH,
};
</script>
<template>
  <searchable-table
    :candidates="items"
    :page-info="pageInfo"
    :error-message="errorMessage"
    :is-loading="isLoading"
    :can-write-model-registry="false"
    @fetch-page="fetchPage"
  >
    <template #empty-state>
      <gl-empty-state
        :title="$options.i18n.emptyStateLabel"
        :svg-path="$options.emptySvgPath"
        class="gl-py-8"
        :description="$options.i18n.emptyStateDescription"
      >
        <template #actions>
          <gl-button
            :href="$options.CANDIDATES_DOCS_PATH"
            variant="confirm"
            class="gl-mx-2 gl-mb-3"
            >{{ $options.i18n.learnMore }}</gl-button
          >
        </template>
      </gl-empty-state>
    </template>
  </searchable-table>
</template>
