<script>
import { __ } from '~/locale';
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
          name: 'username',
          description: __('This is a username.'),
          type: 'string',
          value: 'test',
        },
        {
          name: 'priority',
          description: '',
          type: 'string',
          options: ['1', '2', '3'],
          value: '2',
        },
        {
          name: 'thisOrThat',
          description: __('testing a boolean'),
          type: 'boolean',
          value: 'false',
          required: true,
        },
        {
          name: 'lalala',
          description: __('This is something else.'),
          type: 'number',
          value: 0,
        },
        {
          name: 'userID',
          description: __('This is an ID.'),
          type: 'array',
          value: [{ hello: '2' }, '4', '6'],
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
