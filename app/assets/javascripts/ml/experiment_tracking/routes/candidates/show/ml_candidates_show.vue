<script>
import { GlAvatarLabeled, GlLink } from '@gitlab/ui';
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
  CI_SECTION_LABEL,
  JOB_LABEL,
  CI_USER_LABEL,
  CI_MR_LABEL,
} from './translations';

export default {
  name: 'MlCandidatesShow',
  components: {
    ModelExperimentsHeader,
    DeleteButton,
    DetailRow,
    GlAvatarLabeled,
    GlLink,
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
    CI_SECTION_LABEL,
    JOB_LABEL,
    CI_USER_LABEL,
    CI_MR_LABEL,
  },
  computed: {
    info() {
      return Object.freeze(this.candidate.info);
    },
    ciJob() {
      return Object.freeze(this.info.ci_job);
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

        <detail-row :label="$options.i18n.ID_LABEL" :section-label="$options.i18n.INFO_LABEL">
          {{ info.iid }}
        </detail-row>

        <detail-row :label="$options.i18n.MLFLOW_ID_LABEL">{{ info.eid }}</detail-row>

        <detail-row :label="$options.i18n.STATUS_LABEL">{{ info.status }}</detail-row>

        <detail-row :label="$options.i18n.EXPERIMENT_LABEL">
          <gl-link :href="info.path_to_experiment">
            {{ info.experiment_name }}
          </gl-link>
        </detail-row>

        <detail-row v-if="info.path_to_artifact" :label="$options.i18n.ARTIFACTS_LABEL">
          <gl-link :href="info.path_to_artifact">
            {{ $options.i18n.ARTIFACTS_LABEL }}
          </gl-link>
        </detail-row>

        <template v-if="ciJob">
          <tr class="divider"></tr>

          <detail-row
            :label="$options.i18n.JOB_LABEL"
            :section-label="$options.i18n.CI_SECTION_LABEL"
          >
            <gl-link :href="ciJob.path">
              {{ ciJob.name }}
            </gl-link>
          </detail-row>

          <detail-row v-if="ciJob.user" :label="$options.i18n.CI_USER_LABEL">
            <gl-avatar-labeled label="" :size="24" :src="ciJob.user.avatar">
              <gl-link :href="ciJob.user.path">
                {{ ciJob.user.name }}
              </gl-link>
            </gl-avatar-labeled>
          </detail-row>

          <detail-row v-if="ciJob.merge_request" :label="$options.i18n.CI_MR_LABEL">
            <gl-link :href="ciJob.merge_request.path">
              !{{ ciJob.merge_request.iid }} {{ ciJob.merge_request.title }}
            </gl-link>
          </detail-row>
        </template>

        <template v-for="{ sectionName, sectionValues } in sections">
          <tr v-if="sectionValues" :key="sectionName" class="divider"></tr>

          <detail-row
            v-for="(item, index) in sectionValues"
            :key="item.name"
            :label="item.name"
            :section-label="index === 0 ? sectionName : ''"
          >
            {{ item.value }}
          </detail-row>
        </template>
      </tbody>
    </table>
  </div>
</template>
