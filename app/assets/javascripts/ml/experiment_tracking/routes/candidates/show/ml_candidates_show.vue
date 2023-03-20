<script>
import { GlLink } from '@gitlab/ui';
import { FEATURE_NAME, FEATURE_FEEDBACK_ISSUE } from '~/ml/experiment_tracking/constants';
import IncubationAlert from '~/vue_shared/components/incubation/incubation_alert.vue';
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
} from './translations';

export default {
  name: 'MlCandidatesShow',
  components: {
    IncubationAlert,
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

    <h3>
      {{ $options.i18n.TITLE_LABEL }}
    </h3>

    <table class="candidate-details">
      <tbody>
        <tr class="divider"></tr>

        <tr>
          <td class="gl-text-secondary gl-font-weight-bold">{{ $options.i18n.INFO_LABEL }}</td>
          <td class="gl-font-weight-bold">{{ $options.i18n.ID_LABEL }}</td>
          <td>{{ candidate.info.iid }}</td>
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
