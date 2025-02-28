<script>
import { GlTableLite } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  name: 'PipelineInputsTable',
  components: {
    GlTableLite,
  },
  fields: [
    {
      key: 'name',
      label: __('Name'),
    },
    {
      key: 'description',
      label: __('Description'),
    },
    {
      key: 'type',
      label: __('Type'),
    },
    {
      key: 'value',
      label: __('Value'),
    },
  ],
  props: {
    inputs: {
      type: Array,
      required: true,
    },
  },
};
</script>

<template>
  <gl-table-lite class="gl-mb-0" :items="inputs" :fields="$options.fields" />
</template>
