<script>
import { GlTableLite, GlEmptyState, GlLink } from '@gitlab/ui';
import IncubationAlert from '~/vue_shared/components/incubation/incubation_alert.vue';
import Pagination from '~/vue_shared/components/incubation/pagination.vue';
import { FEATURE_NAME, FEATURE_FEEDBACK_ISSUE } from '~/ml/experiment_tracking/constants';
import * as constants from '~/ml/experiment_tracking/routes/experiments/index/constants';
import * as translations from '~/ml/experiment_tracking/routes/experiments/index/translations';

export default {
  name: 'MlExperimentsIndexApp',
  components: {
    Pagination,
    IncubationAlert,
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
    <h1 class="page-title gl-font-size-h-display">
      {{ $options.i18n.TITLE_LABEL }}
    </h1>

    <incubation-alert
      :feature-name="$options.constants.FEATURE_NAME"
      :link-to-feedback-issue="$options.constants.FEATURE_FEEDBACK_ISSUE"
    />

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
