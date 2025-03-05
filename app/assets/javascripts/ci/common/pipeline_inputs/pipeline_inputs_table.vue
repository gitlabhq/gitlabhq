<script>
import { GlTableLite } from '@gitlab/ui';
import { __ } from '~/locale';
import DynamicValueRenderer from './dynamic_value_renderer.vue';

export default {
  name: 'PipelineInputsTable',
  components: {
    DynamicValueRenderer,
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
      key: 'default',
      label: __('Value'),
      thAttr: { 'data-testid': 'input-values-th' },
    },
  ],
  props: {
    inputs: {
      type: Array,
      required: true,
    },
  },
  emits: ['update'],
  methods: {
    handleValueUpdated({ item, value }) {
      const updatedInput = { ...item, value };
      this.$emit('update', updatedInput);
    },
  },
};
</script>

<template>
  <gl-table-lite
    class="gl-mb-0"
    :items="inputs"
    :fields="$options.fields"
    :tbody-tr-attr="{ 'data-testid': 'input-row' }"
    stacked="sm"
  >
    <template #cell(name)="{ item }">
      <span>
        {{ item.name }}
        <span v-if="item.required" class="gl-text-danger" data-testid="required-asterisk">*</span>
      </span>
    </template>
    <template #cell(description)="{ item }">
      {{ item.description || '-' }}
    </template>
    <template #cell(default)="{ item }">
      <dynamic-value-renderer :item="item" @update="handleValueUpdated" />
    </template>
  </gl-table-lite>
</template>
