<script>
import { GlEmptyState, GlButton } from '@gitlab/ui';
import emptySvgUrl from '@gitlab/svgs/dist/illustrations/status/status-new-md.svg';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { s__, __, sprintf } from '~/locale';
import getExperimentCandidates from '~/ml/experiment_tracking/graphql/queries/get_experiment_candidates.query.graphql';
import SearchableTable from '~/ml/model_registry/components/searchable_table.vue';
import { GRAPHQL_PAGE_SIZE, CANDIDATES_DOCS_PATH } from '../constants';

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
      skipQueries: true,
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
          <gl-button :href="$options.CANDIDATES_DOCS_PATH" variant="confirm" class="gl-mx-2 gl-mb-3"
            >{{ $options.i18n.learnMore }}
          </gl-button>
        </template>
      </gl-empty-state>
    </template>
  </searchable-table>
</template>
