<script>
import { GlTableLite, GlEmptyState, GlLink, GlButton, GlModalDirective } from '@gitlab/ui';
import { FEATURE_NAME, FEATURE_FEEDBACK_ISSUE } from '~/ml/experiment_tracking/constants';
import * as constants from '~/ml/experiment_tracking/routes/experiments/index/constants';
import * as translations from '~/ml/experiment_tracking/routes/experiments/index/translations';
import ModelExperimentsHeader from '~/ml/experiment_tracking/components/model_experiments_header.vue';
import Pagination from '~/ml/experiment_tracking/components/pagination.vue';
import { MLFLOW_USAGE_MODAL_ID } from '../constants';
import MlflowModal from './mlflow_usage_modal.vue';

export default {
  name: 'MlExperimentsIndexApp',
  components: {
    Pagination,
    ModelExperimentsHeader,
    GlTableLite,
    GlEmptyState,
    GlLink,
    GlButton,
    MlflowModal,
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
  },
  tableFields: constants.EXPERIMENTS_TABLE_FIELDS,
  i18n: translations,
  computed: {
    hasExperiments() {
      return this.experiments.length > 0;
    },
    tableItems() {
      return this.experiments.map((exp) => ({
        nameColumn: { name: exp.name, path: exp.path },
        candidateCountColumn: exp.candidate_count,
      }));
    },
  },
  constants: {
    FEATURE_NAME,
    FEATURE_FEEDBACK_ISSUE,
    ...constants,
  },
  mlflowModalId: MLFLOW_USAGE_MODAL_ID,
};
</script>

<template>
  <div>
    <model-experiments-header :page-title="$options.i18n.TITLE_LABEL" />

    <template v-if="hasExperiments">
      <gl-table-lite :items="tableItems" :fields="$options.tableFields">
        <template #cell(nameColumn)="data">
          <gl-link :href="data.value.path">
            {{ data.value.name }}
          </gl-link>
        </template>
      </gl-table-lite>

      <pagination v-if="hasExperiments" v-bind="pageInfo" />
    </template>

    <gl-empty-state
      v-else
      :title="$options.i18n.EMPTY_STATE_TITLE_LABEL"
      :svg-path="emptyStateSvgPath"
      :svg-height="null"
      :description="$options.i18n.EMPTY_STATE_DESCRIPTION_LABEL"
      class="gl-py-8"
    >
      <template #actions>
        <gl-button v-gl-modal="$options.mlflowModalId" class="gl-mx-2 gl-mb-3 gl-mr-3">
          {{ $options.i18n.CREATE_USING_MLFLOW_LABEL }}
        </gl-button>
      </template>
    </gl-empty-state>

    <mlflow-modal />
  </div>
</template>
