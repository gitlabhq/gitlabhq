<script>
import { GlLink } from '@gitlab/ui';
import { FEATURE_NAME, FEATURE_FEEDBACK_ISSUE } from '~/ml/experiment_tracking/constants';
import IncubationAlert from '~/vue_shared/components/incubation/incubation_alert.vue';
import DeleteButton from '~/ml/experiment_tracking/components/delete_button.vue';
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
    IncubationAlert,
    DeleteButton,
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
    PARAMETERS_LABEL,
    METRICS_LABEL,
    METADATA_LABEL,
    DELETE_CANDIDATE_CONFIRMATION_MESSAGE,
    DELETE_CANDIDATE_PRIMARY_ACTION_LABEL,
    DELETE_CANDIDATE_MODAL_TITLE,
    MLFLOW_ID_LABEL,
  },
  computed: {
    sections() {
      return [
        {
          sectionName: this.$options.i18n.PARAMETERS_LABEL,
          sectionValues: this.candidate.params,
        },
        {
          sectionName: this.$options.i18n.METRICS_LABEL,
          sectionValues: this.candidate.metrics,
        },
        {
          sectionName: this.$options.i18n.METADATA_LABEL,
          sectionValues: this.candidate.metadata,
        },
      ];
    },
  },
  FEATURE_NAME,
  FEATURE_FEEDBACK_ISSUE,
};
</script>

<template>
  <div>
    <incubation-alert
      :feature-name="$options.FEATURE_NAME"
      :link-to-feedback-issue="$options.FEATURE_FEEDBACK_ISSUE"
    />

    <div class="detail-page-header gl-flex-wrap">
      <div class="detail-page-header-body">
        <h1 class="page-title gl-font-size-h-display flex-fill">
          {{ $options.i18n.TITLE_LABEL }}
        </h1>

        <delete-button
          :delete-path="candidate.info.path"
          :delete-confirmation-text="$options.i18n.DELETE_CANDIDATE_CONFIRMATION_MESSAGE"
          :action-primary-text="$options.i18n.DELETE_CANDIDATE_PRIMARY_ACTION_LABEL"
          :modal-title="$options.i18n.DELETE_CANDIDATE_MODAL_TITLE"
        />
      </div>
    </div>

    <table class="candidate-details gl-w-full">
      <tbody>
        <tr class="divider"></tr>

        <tr>
          <td class="gl-text-secondary gl-font-weight-bold">{{ $options.i18n.INFO_LABEL }}</td>
          <td class="gl-font-weight-bold">{{ $options.i18n.ID_LABEL }}</td>
          <td>{{ candidate.info.iid }}</td>
        </tr>

        <tr>
          <td></td>
          <td class="gl-font-weight-bold">{{ $options.i18n.MLFLOW_ID_LABEL }}</td>
          <td>{{ candidate.info.eid }}</td>
        </tr>

        <tr>
          <td></td>
          <td class="gl-font-weight-bold">{{ $options.i18n.STATUS_LABEL }}</td>
          <td>{{ candidate.info.status }}</td>
        </tr>

        <tr>
          <td></td>
          <td class="gl-font-weight-bold">{{ $options.i18n.EXPERIMENT_LABEL }}</td>
          <td>
            <gl-link :href="candidate.info.path_to_experiment">{{
              candidate.info.experiment_name
            }}</gl-link>
          </td>
        </tr>

        <tr v-if="candidate.info.path_to_artifact">
          <td></td>
          <td class="gl-font-weight-bold">{{ $options.i18n.ARTIFACTS_LABEL }}</td>
          <td>
            <gl-link :href="candidate.info.path_to_artifact">{{
              $options.i18n.ARTIFACTS_LABEL
            }}</gl-link>
          </td>
        </tr>

        <template v-for="{ sectionName, sectionValues } in sections">
          <tr :key="sectionName" class="divider"></tr>

          <tr v-for="(item, index) in sectionValues" :key="item.name">
            <td v-if="index === 0" class="gl-text-secondary gl-font-weight-bold">
              {{ sectionName }}
            </td>
            <td v-else></td>
            <td class="gl-font-weight-bold">{{ item.name }}</td>
            <td>{{ item.value }}</td>
          </tr>
        </template>
      </tbody>
    </table>
  </div>
</template>
