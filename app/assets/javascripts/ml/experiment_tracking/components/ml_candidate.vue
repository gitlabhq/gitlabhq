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

        <tr class="divider"></tr>

        <tr v-for="(param, index) in candidate.params" :key="param.name">
          <td v-if="index == 0" class="gl-text-secondary gl-font-weight-bold">
            {{ $options.i18n.parametersLabel }}
          </td>
          <td v-else></td>
          <td class="gl-font-weight-bold">{{ param.name }}</td>
          <td>{{ param.value }}</td>
        </tr>

        <tr class="divider"></tr>

        <tr v-for="(metric, index) in candidate.metrics" :key="metric.name">
          <td v-if="index == 0" class="gl-text-secondary gl-font-weight-bold">
            {{ $options.i18n.metricsLabel }}
          </td>
          <td v-else></td>
          <td class="gl-font-weight-bold">{{ metric.name }}</td>
          <td>{{ metric.value }}</td>
        </tr>
      </tbody>
    </table>
  </div>
</template>
