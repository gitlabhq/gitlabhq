<script>
import { GlTable } from '@gitlab/ui';
import IncubationAlert from './incubation_alert.vue';

export default {
  name: 'ShowMlExperiment',
  components: {
    GlTable,
    IncubationAlert,
  },
  inject: ['candidates', 'metricNames', 'paramNames'],
  computed: {
    fields() {
      return [...this.paramNames, ...this.metricNames];
    },
  },
};
</script>

<template>
  <div>
    <incubation-alert />

    <h3>
      {{ __('Experiment Candidates') }}
    </h3>

    <gl-table
      :fields="fields"
      :items="candidates"
      :empty-text="__('This Experiment has no logged Candidates')"
      show-empty
      class="gl-mt-0!"
    />
  </div>
</template>
