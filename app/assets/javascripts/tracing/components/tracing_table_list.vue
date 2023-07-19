<script>
import { GlTable, GlLink } from '@gitlab/ui';
import { __ } from '~/locale';

export const tableDataClass = 'gl-display-flex gl-md-display-table-cell gl-align-items-center';
export default {
  name: 'TracingTableList',
  i18n: {
    title: __('Traces'),
    emptyText: __('No traces to display.'),
    emptyLinkText: __('Check again'),
  },
  fields: [
    {
      key: 'date',
      label: __('Date'),
      tdClass: tableDataClass,
      sortable: true,
    },
    {
      key: 'service',
      label: __('Service'),
      tdClass: tableDataClass,
      sortable: true,
    },
    {
      key: 'operation',
      label: __('Operation'),
      tdClass: tableDataClass,
      sortable: true,
    },
    {
      key: 'duration',
      label: __('Duration'),
      thClass: 'gl-w-15p',
      tdClass: tableDataClass,
      sortable: true,
    },
  ],
  components: {
    GlTable,
    GlLink,
  },
  props: {
    traces: {
      required: true,
      type: Array,
    },
  },
};
</script>

<template>
  <div>
    <h4 class="gl-display-block gl-md-display-none! gl-my-5">{{ $options.i18n.title }}</h4>

    <gl-table
      class="gl-mt-5"
      :items="traces"
      :fields="$options.fields"
      show-empty
      fixed
      stacked="md"
      tbody-tr-class="table-row"
    >
      <template #cell(date)="data">
        {{ data.item.timestamp }}
      </template>

      <template #cell(service)="data">
        {{ data.item.service_name }}
      </template>

      <template #cell(operation)="data">
        {{ data.item.operation }}
      </template>

      <template #cell(duration)="data">
        <!-- eslint-disable-next-line @gitlab/vue-require-i18n-strings -->
        {{ `${data.item.duration} ms` }}
      </template>

      <template #empty>
        {{ $options.i18n.emptyText }}
        <gl-link @click="$emit('reload')">{{ $options.i18n.emptyLinkText }}</gl-link>
      </template>
    </gl-table>
  </div>
</template>
