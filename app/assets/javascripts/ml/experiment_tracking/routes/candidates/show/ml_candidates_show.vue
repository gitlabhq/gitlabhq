<script>
import ModelExperimentsHeader from '~/ml/experiment_tracking/components/model_experiments_header.vue';
import DeleteButton from '~/ml/experiment_tracking/components/delete_button.vue';
import DetailRow from './components/candidate_detail_row.vue';

import {
  TITLE_LABEL,
  INFO_LABEL,
  ID_LABEL,
  STATUS_LABEL,
  EXPERIMENT_LABEL,
  ARTIFACTS_LABEL,
  PARAMETERS_LABEL,
  METRICS_LABEL,
  METADATA_LABEL,
  DELETE_CANDIDATE_CONFIRMATION_MESSAGE,
  DELETE_CANDIDATE_PRIMARY_ACTION_LABEL,
  DELETE_CANDIDATE_MODAL_TITLE,
  MLFLOW_ID_LABEL,
} from './translations';

export default {
  name: 'MlCandidatesShow',
  components: {
    ModelExperimentsHeader,
    DeleteButton,
    DetailRow,
  },
  props: {
    candidate: {
      type: Object,
      required: true,
    },
  },
  i18n: {
    TITLE_LABEL,
    INFO_LABEL,
    ID_LABEL,
    STATUS_LABEL,
    EXPERIMENT_LABEL,
    ARTIFACTS_LABEL,
    DELETE_CANDIDATE_CONFIRMATION_MESSAGE,
    DELETE_CANDIDATE_PRIMARY_ACTION_LABEL,
    DELETE_CANDIDATE_MODAL_TITLE,
    MLFLOW_ID_LABEL,
  },
  computed: {
    info() {
      return Object.freeze(this.candidate.info);
    },
    sections() {
      return [
        {
          sectionName: PARAMETERS_LABEL,
          sectionValues: this.candidate.params,
        },
        {
          sectionName: METRICS_LABEL,
          sectionValues: this.candidate.metrics,
        },
        {
          sectionName: METADATA_LABEL,
          sectionValues: this.candidate.metadata,
        },
      ];
    },
  },
};
</script>

<template>
  <div>
    <model-experiments-header :page-title="$options.i18n.TITLE_LABEL">
      <delete-button
        :delete-path="info.path"
        :delete-confirmation-text="$options.i18n.DELETE_CANDIDATE_CONFIRMATION_MESSAGE"
        :action-primary-text="$options.i18n.DELETE_CANDIDATE_PRIMARY_ACTION_LABEL"
        :modal-title="$options.i18n.DELETE_CANDIDATE_MODAL_TITLE"
      />
    </model-experiments-header>

    <table class="candidate-details gl-w-full">
      <tbody>
        <tr class="divider"></tr>

        <detail-row
          :label="$options.i18n.ID_LABEL"
          :section-label="$options.i18n.INFO_LABEL"
          :text="info.iid"
        />

        <detail-row :label="$options.i18n.MLFLOW_ID_LABEL" :text="info.eid" />

        <detail-row :label="$options.i18n.STATUS_LABEL" :text="info.status" />

        <detail-row
          :label="$options.i18n.EXPERIMENT_LABEL"
          :text="info.experiment_name"
          :href="info.path_to_experiment"
        />

        <detail-row
          v-if="info.path_to_artifact"
          :label="$options.i18n.ARTIFACTS_LABEL"
          :href="info.path_to_artifact"
          :text="$options.i18n.ARTIFACTS_LABEL"
        />

        <template v-for="{ sectionName, sectionValues } in sections">
          <tr v-if="sectionValues" :key="sectionName" class="divider"></tr>

          <detail-row
            v-for="(item, index) in sectionValues"
            :key="item.name"
            :label="item.name"
            :section-label="index === 0 ? sectionName : ''"
            :text="item.value"
          />
        </template>
      </tbody>
    </table>
  </div>
</template>
