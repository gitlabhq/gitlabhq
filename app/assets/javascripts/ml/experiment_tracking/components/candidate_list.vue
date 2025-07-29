<script>
import { GlEmptyState, GlButton } from '@gitlab/ui';
import EMPTY_SVG_PATH from '@gitlab/svgs/dist/illustrations/status/status-new-md.svg';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { s__, __, sprintf } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import getExperimentCandidates from '~/ml/experiment_tracking/graphql/queries/get_experiment_candidates.query.graphql';
import SearchableTable from '~/ml/model_registry/components/searchable_table.vue';
import CandidatesTable from '~/ml/model_registry/components/candidates_table.vue';

const GRAPHQL_PAGE_SIZE = 30;

export default {
  name: 'MlCandidateList',
  components: {
    SearchableTable,
    GlButton,
    GlEmptyState,
  },
  props: {
    experimentId: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      candidates: {},
      errorMessage: '',
      queryVariables: undefined,
    };
  },
  apollo: {
    candidates: {
      query: getExperimentCandidates,
      variables() {
        return this.queryVariables;
      },
      update(data) {
        return data.mlExperiment?.candidates ?? {};
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
    candidatesTableComponent() {
      return CandidatesTable;
    },
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
        id: this.experimentId,
        first: GRAPHQL_PAGE_SIZE,
        ...variables,
      };
    },
    handleError(error) {
      this.errorMessage = sprintf(
        s__('MlExperimentTracking|Failed to load experiment candidates with error: %{message}'),
        {
          message: error.message,
        },
      );
      Sentry.captureException(error);
    },
  },
  i18n: {
    learnMore: __('Learn more'),
    emptyStateLabel: s__('MlExperimentTracking|No candidates associated with this experiment'),
    emptyStateDescription: s__(
      'MlExperimentTracking|Use candidates to track performance, parameters, and metadata',
    ),
  },
  CANDIDATES_DOCS_PATH: helpPagePath('user/project/ml/experiment_tracking/mlflow_client.md', {
    anchor: 'logging-runs-to-a-model',
  }),
  EMPTY_SVG_PATH,
};
</script>
<template>
  <searchable-table
    :items="items"
    :table="candidatesTableComponent"
    :page-info="pageInfo"
    :error-message="errorMessage"
    :is-loading="isLoading"
    :can-write-model-registry="false"
    @fetch-page="fetchPage"
  >
    <template #empty-state>
      <gl-empty-state
        :title="$options.i18n.emptyStateLabel"
        :svg-path="$options.EMPTY_SVG_PATH"
        class="gl-py-8"
        :description="$options.i18n.emptyStateDescription"
      >
        <template #actions>
          <gl-button :href="$options.CANDIDATES_DOCS_PATH" variant="confirm" class="gl-mx-2 gl-mb-3"
            >{{ $options.i18n.learnMore }}
          </gl-button>
        </template>
      </gl-empty-state>
    </template>
  </searchable-table>
</template>
