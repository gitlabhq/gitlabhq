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
          value: 'testuser',
        },
        {
          name: 'userID',
          description: __('This is an ID.'),
          type: 'number',
          value: '001',
        },
      ],
    };
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
    <pipeline-inputs-table :inputs="inputs" />
  </crud-component>
</template>
