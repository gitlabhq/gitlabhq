<script>
import {
  GlAlert,
  GlAvatar,
  GlAvatarLink,
  GlButton,
  GlEmptyState,
  GlKeysetPagination,
  GlLink,
  GlModalDirective,
  GlTableLite,
} from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import ModelExperimentsHeader from '~/ml/experiment_tracking/components/model_experiments_header.vue';
import getExperimentsQuery from '~/ml/experiment_tracking/graphql/queries/get_experiments.query.graphql';
import { MLFLOW_USAGE_MODAL_ID } from '../constants';

const GRAPHQL_PAGE_SIZE = 20;

export default {
  name: 'MlExperimentsIndexApp',
  components: {
    GlAlert,
    GlAvatar,
    GlAvatarLink,
    GlButton,
    GlEmptyState,
    GlKeysetPagination,
    GlLink,
    GlTableLite,
    ModelExperimentsHeader,
    TimeAgoTooltip,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  provide() {
    return {
      mlflowTrackingUrl: this.mlflowTrackingUrl,
    };
  },
  props: {
    projectPath: {
      type: String,
      required: true,
    },
    emptyStateSvgPath: {
      type: String,
      required: true,
    },
    mlflowTrackingUrl: {
      type: String,
      required: false,
      default: '',
    },
  },
  apollo: {
    experiments: {
      query: getExperimentsQuery,
      variables() {
        return this.queryVariables;
      },
      update(data) {
        return data?.project?.mlExperiments ?? [];
      },
      error(error) {
        this.errorMessage = sprintf(
          s__('MlExperimentTracking|Failed to load experiments with error: %{error}'),
          { error: error.message },
        );
        Sentry.captureException(error);
      },
      skip() {
        return this.skipQueries;
      },
    },
  },
  data() {
    return {
      experiments: [],
      errorMessage: '',
      skipQueries: false,
      pageVariables: { first: GRAPHQL_PAGE_SIZE },
    };
  },
  computed: {
    pageInfo() {
      return this.experiments?.pageInfo ?? {};
    },
    showExperimentsTable() {
      return this.count;
    },
    showEmptyState() {
      return this.experiments?.count === 0 && !this.isLoading;
    },
    tableItems() {
      return this.items.map((exp) => ({
        nameColumn: {
          name: exp.name,
          path: exp.path,
        },
        candidateCountColumn: exp.candidateCount,
        creatorColumn: exp.creator
          ? { ...exp.creator, iid: getIdFromGraphQLId(exp.creator.id) }
          : null,
        lastActivityColumn: exp.updatedAt,
      }));
    },
    items() {
      return this.experiments?.nodes ?? [];
    },
    count() {
      return this.experiments?.count ?? 0;
    },
    isLoading() {
      return this.$apollo.queries.experiments.loading;
    },
    queryVariables() {
      return {
        fullPath: this.projectPath,
        first: GRAPHQL_PAGE_SIZE,
        ...this.pageVariables,
      };
    },
  },
  methods: {
    nextPage() {
      this.pageVariables = {
        first: GRAPHQL_PAGE_SIZE,
        last: null,
        after: this.pageInfo.endCursor,
      };
    },
    prevPage() {
      this.pageVariables = {
        first: null,
        last: GRAPHQL_PAGE_SIZE,
        before: this.pageInfo.startCursor,
      };
    },
  },
  i18n: {
    createUsingMlflowLabel: s__('MlExperimentTracking|Create an experiment using MLflow'),
    emptyStateTitleLabel: s__('MlExperimentTracking|Get started with model experiments!'),
    titleLabel: s__('MlExperimentTracking|Model experiments'),
    emptyStateDescriptionLabel: s__(
      'MlExperimentTracking|Experiments keep track of comparable model runs, and determine which parameters provides the best performance.',
    ),
  },
  tableFields: [
    { key: 'nameColumn', label: s__('MlExperimentTracking|Name') },
    {
      key: 'candidateCountColumn',
      label: s__('MlExperimentTracking|Number of runs'),
    },
    { key: 'creatorColumn', label: s__('MlExperimentTracking|Creator') },
    { key: 'lastActivityColumn', label: s__('MlExperimentTracking|Last activity') },
  ],
  mlflowModalId: MLFLOW_USAGE_MODAL_ID,
};
</script>

<template>
  <div>
    <model-experiments-header :page-title="$options.i18n.titleLabel" :count="count" />

    <template v-if="showExperimentsTable">
      <gl-table-lite :items="tableItems" :fields="$options.tableFields">
        <template #cell(nameColumn)="{ value: experiment }">
          <gl-link :href="experiment.path">
            {{ experiment.name }}
          </gl-link>
        </template>
        <template #cell(creatorColumn)="{ value: creator }">
          <gl-avatar-link
            v-if="creator"
            :href="creator.webUrl"
            :title="creator.name"
            class="js-user-link gl-text-subtle"
            :data-user-id="creator.iid"
          >
            <gl-avatar
              :src="creator.avatarUrl"
              :size="16"
              :entity-name="creator.name"
              class="!gl-mr-3"
            />
            {{ creator.name }}
          </gl-avatar-link>
        </template>
        <template #cell(lastActivityColumn)="{ value: updatedAt }">
          <time-ago-tooltip :time="updatedAt" />
        </template>
      </gl-table-lite>

      <gl-keyset-pagination v-bind="pageInfo" @prev="prevPage" @next="nextPage" />
    </template>
    <gl-empty-state
      v-if="showEmptyState"
      :title="$options.i18n.emptyStateTitleLabel"
      :svg-path="emptyStateSvgPath"
      :svg-height="null"
      :description="$options.i18n.emptyStateDescriptionLabel"
      class="gl-py-8"
    >
      <template #actions>
        <gl-button
          v-gl-modal="$options.mlflowModalId"
          data-testid="empty-create-using-button"
          class="gl-mx-2 gl-mb-3 gl-mr-3"
        >
          {{ $options.i18n.createUsingMlflowLabel }}
        </gl-button>
      </template>
    </gl-empty-state>
    <gl-alert v-if="errorMessage" variant="warning" :dismissible="false">
      {{ errorMessage }}
    </gl-alert>
  </div>
</template>
