<script>
import { GlTable, GlLink } from '@gitlab/ui';
import { s__ } from '~/locale';

export const tableDataClass = 'gl-display-flex gl-md-display-table-cell gl-align-items-center';
export default {
  name: 'TracingTableList',
  i18n: {
    title: s__('Tracing|Traces'),
    emptyText: s__('Tracing|No traces to display.'),
    emptyLinkText: s__('Tracing|Check again'),
  },
  fields: [
    {
      key: 'timestamp',
      label: s__('Tracing|Date'),
      tdClass: tableDataClass,
      sortable: true,
    },
    {
      key: 'service_name',
      label: s__('Tracing|Service'),
      tdClass: tableDataClass,
      sortable: true,
    },
    {
      key: 'operation',
      label: s__('Tracing|Operation'),
      tdClass: tableDataClass,
      sortable: true,
    },
    {
      key: 'duration',
      label: s__('Tracing|Duration'),
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
  methods: {
    onSelect(items) {
      if (items[0]) {
        this.$emit('trace-selected', items[0]);
      }
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
      sort-by="timestamp"
      :sort-desc="true"
      fixed
      stacked="md"
      tbody-tr-class="table-row"
      selectable
      select-mode="single"
      selected-variant=""
      @row-selected="onSelect"
    >
      <template #cell(timestamp)="data">
        {{ data.item.timestamp }}
      </template>

      <template #cell(service_name)="data">
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
