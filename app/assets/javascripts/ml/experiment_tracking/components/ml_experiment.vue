<script>
import { GlTable, GlLink } from '@gitlab/ui';
import { __ } from '~/locale';
import IncubationAlert from './incubation_alert.vue';

export default {
  name: 'MlExperiment',
  components: {
    GlTable,
    GlLink,
    IncubationAlert,
  },
  inject: ['candidates', 'metricNames', 'paramNames'],
  computed: {
    fields() {
      return [
        ...this.paramNames,
        ...this.metricNames,
        { key: 'details', label: '' },
        { key: 'artifact', label: '' },
      ];
    },
  },
  i18n: {
    titleLabel: __('Experiment candidates'),
    emptyStateLabel: __('This experiment has no logged candidates'),
    artifactsLabel: __('Artifacts'),
    detailsLabel: __('Details'),
  },
};
</script>

<template>
  <div>
    <incubation-alert />

    <h3>
      {{ $options.i18n.titleLabel }}
    </h3>

    <gl-table
      :fields="fields"
      :items="candidates"
      :empty-text="$options.i18n.emptyStateLabel"
      show-empty
      class="gl-mt-0!"
    >
      <template #cell(artifact)="data">
        <gl-link v-if="data.value" :href="data.value" target="_blank">{{
          $options.i18n.artifactsLabel
        }}</gl-link>
      </template>

      <template #cell(details)="data">
        <gl-link :href="data.value">{{ $options.i18n.detailsLabel }}</gl-link>
      </template>
    </gl-table>
  </div>
</template>
