<script>
import {
  GlAvatar,
  GlAvatarLink,
  GlButton,
  GlEmptyState,
  GlLink,
  GlModalDirective,
  GlTableLite,
} from '@gitlab/ui';
import { s__ } from '~/locale';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import ModelExperimentsHeader from '~/ml/experiment_tracking/components/model_experiments_header.vue';
import Pagination from '~/ml/experiment_tracking/components/pagination.vue';
import { MLFLOW_USAGE_MODAL_ID } from '../constants';

export default {
  name: 'MlExperimentsIndexApp',
  components: {
    GlAvatar,
    GlAvatarLink,
    GlButton,
    GlEmptyState,
    GlLink,
    GlTableLite,
    ModelExperimentsHeader,
    Pagination,
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
    experiments: {
      type: Array,
      required: true,
    },
    pageInfo: {
      type: Object,
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
    count: {
      type: Number,
      required: true,
    },
  },
  computed: {
    hasExperiments() {
      return this.experiments.length > 0;
    },
    tableItems() {
      return this.experiments.map((exp) => ({
        nameColumn: { name: exp.name, path: exp.path },
        candidateCountColumn: exp.candidate_count,
        creatorColumn: exp.user,
        lastActivityColumn: exp.updated_at,
      }));
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

    <template v-if="hasExperiments">
      <gl-table-lite :items="tableItems" :fields="$options.tableFields">
        <template #cell(nameColumn)="{ value: experiment }">
          <gl-link :href="experiment.path">
            {{ experiment.name }}
          </gl-link>
        </template>
        <template #cell(creatorColumn)="{ value: creator }">
          <gl-avatar-link
            v-if="creator"
            :href="creator.path"
            :title="creator.name"
            class="js-user-link gl-text-subtle"
            :data-user-id="creator.id"
          >
            <gl-avatar
              :src="creator.avatar_url"
              :size="16"
              :entity-name="creator.name"
              class="mr-2"
            />
            {{ creator.name }}
          </gl-avatar-link>
        </template>
        <template #cell(lastActivityColumn)="{ value: updatedAt }">
          <time-ago-tooltip :time="updatedAt" />
        </template>
      </gl-table-lite>

      <pagination v-if="hasExperiments" v-bind="pageInfo" />
    </template>
    <gl-empty-state
      v-else
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
  </div>
</template>
