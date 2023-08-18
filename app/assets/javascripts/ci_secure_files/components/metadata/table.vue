<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlTableLite } from '@gitlab/ui';

export default {
  components: {
    GlTableLite,
  },
  props: {
    items: {
      required: true,
      type: Array,
    },
  },
  fields: [
    {
      key: 'item_name',
      thClass: 'hidden',
    },
    {
      key: 'item_data',
      thClass: 'hidden',
    },
  ],
};
</script>

<template>
  <gl-table-lite :items="items" :fields="$options.fields">
    <template #cell(item_name)="{ item }">
      <strong>{{ item.name }}</strong>
    </template>
    <template #cell(item_data)="{ item }">
      {{ item.data }}
    </template>
  </gl-table-lite>
</template>
