<script>
import { GlTableLite, GlEmptyState, GlLink } from '@gitlab/ui';
import Pagination from '~/vue_shared/components/incubation/pagination.vue';
import { FEATURE_NAME, FEATURE_FEEDBACK_ISSUE } from '~/ml/experiment_tracking/constants';
import * as constants from '~/ml/experiment_tracking/routes/experiments/index/constants';
import * as translations from '~/ml/experiment_tracking/routes/experiments/index/translations';
import ModelExperimentsHeader from '~/ml/experiment_tracking/components/model_experiments_header.vue';

export default {
  name: 'MlExperimentsIndexApp',
  components: {
    Pagination,
    ModelExperimentsHeader,
    GlTableLite,
    GlEmptyState,
    GlLink,
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
};
</script>

<template>
  <div v-if="hasExperiments">
    <model-experiments-header :page-title="$options.i18n.TITLE_LABEL" />

    <gl-table-lite :items="tableItems" :fields="$options.tableFields">
      <template #cell(nameColumn)="data">
        <gl-link :href="data.value.path">
          {{ data.value.name }}
        </gl-link>
      </template>
    </gl-table-lite>

    <pagination v-if="hasExperiments" v-bind="pageInfo" />
  </div>

  <gl-empty-state
    v-else
    :title="$options.i18n.EMPTY_STATE_TITLE_LABEL"
    :primary-button-text="$options.i18n.CREATE_NEW_LABEL"
    :primary-button-link="$options.constants.CREATE_EXPERIMENT_HELP_PATH"
    :svg-path="emptyStateSvgPath"
    :description="$options.i18n.EMPTY_STATE_DESCRIPTION_LABEL"
    class="gl-py-8"
  />
</template>
