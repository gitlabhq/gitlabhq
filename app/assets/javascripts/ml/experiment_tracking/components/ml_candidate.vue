<script>
import { GlLink } from '@gitlab/ui';
import { __ } from '~/locale';
import IncubationAlert from './incubation_alert.vue';

export default {
  name: 'MlCandidate',
  components: {
    IncubationAlert,
    GlLink,
  },
  inject: ['candidate'],
  i18n: {
    titleLabel: __('Model candidate details'),
    infoLabel: __('Info'),
    idLabel: __('ID'),
    statusLabel: __('Status'),
    experimentLabel: __('Experiment'),
    artifactsLabel: __('Artifacts'),
    parametersLabel: __('Parameters'),
    metricsLabel: __('Metrics'),
    metadataLabel: __('Metadata'),
  },
  computed: {
    sections() {
      return [
        {
          sectionName: this.$options.i18n.parametersLabel,
          sectionValues: this.candidate.params,
        },
        {
          sectionName: this.$options.i18n.metricsLabel,
          sectionValues: this.candidate.metrics,
        },
        {
          sectionName: this.$options.i18n.metadataLabel,
          sectionValues: this.candidate.metadata,
        },
      ];
    },
  },
};
</script>

<template>
  <div>
    <incubation-alert />

    <h3>
      {{ $options.i18n.titleLabel }}
    </h3>

    <table class="candidate-details">
      <tbody>
        <tr class="divider"></tr>

        <tr>
          <td class="gl-text-secondary gl-font-weight-bold">{{ $options.i18n.infoLabel }}</td>
          <td class="gl-font-weight-bold">{{ $options.i18n.idLabel }}</td>
          <td>{{ candidate.info.iid }}</td>
        </tr>

        <tr>
          <td></td>
          <td class="gl-font-weight-bold">{{ $options.i18n.statusLabel }}</td>
          <td>{{ candidate.info.status }}</td>
        </tr>

        <tr>
          <td></td>
          <td class="gl-font-weight-bold">{{ $options.i18n.experimentLabel }}</td>
          <td>
            <gl-link :href="candidate.info.path_to_experiment">{{
              candidate.info.experiment_name
            }}</gl-link>
          </td>
        </tr>

        <tr v-if="candidate.info.path_to_artifact">
          <td></td>
          <td class="gl-font-weight-bold">{{ $options.i18n.artifactsLabel }}</td>
          <td>
            <gl-link :href="candidate.info.path_to_artifact">{{
              $options.i18n.artifactsLabel
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
