<!-- eslint-disable @gitlab/require-i18n-strings -->
<script>
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import PipelineInputsTable from './pipeline_inputs_table.vue';

export default {
  name: 'PipelineInputsForm',
  components: {
    CrudComponent,
    PipelineInputsTable,
  },
  data() {
    return {
      inputs: [
        {
          name: 'environment',
          description: 'Target **deployment** environment',
          type: 'STRING',
          required: true,
          regex: '^(production|staging|development)$',
          default: 'development',
          options: ['production', 'staging', 'development'],
        },
        {
          name: 'api_version',
          description: 'API version format (e.g. v1, v2.1)',
          type: 'STRING',
          required: true,
          regex: '^v\\d+(\\.\\d+)?$',
          default: 'v1',
          options: null,
        },
        {
          name: 'debug_mode',
          description: '',
          type: 'BOOLEAN',
          required: false,
          regex: null,
          default: false,
          options: null,
        },
        {
          name: 'replicas',
          description: 'Number of replicas to deploy',
          type: 'NUMBER',
          required: true,
          regex: '^[1-9][0-9]*$',
          default: 1,
          options: null,
        },
      ],
    };
  },
  methods: {
    handleInputUpdated(updatedInput) {
      this.inputs = this.inputs.map((input) =>
        input.name === updatedInput.name ? updatedInput : input,
      );
    },
  },
};
</script>

<template>
  <crud-component
    :count="inputs.length"
    :description="__('Specify the input values to use in this pipeline.')"
    :title="s__('Pipelines|Inputs')"
    icon="code"
  >
    <pipeline-inputs-table :inputs="inputs" @update="handleInputUpdated" />
  </crud-component>
</template>
