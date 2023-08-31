<script>
import { GlTable, GlLink, GlTruncate } from '@gitlab/ui';
import { s__ } from '~/locale';
import { formatDate } from '~/lib/utils/datetime/date_format_utility';
import { formatTraceDuration } from './trace_utils';

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
    GlTruncate,
  },
  props: {
    traces: {
      required: true,
      type: Array,
    },
  },
  computed: {
    formattedTraces() {
      return this.traces.map((x) => ({
        ...x,
        timestamp: formatDate(x.timestamp),
        duration: formatTraceDuration(x.duration_nano),
      }));
    },
  },
  methods: {
    onSelect(items) {
      if (items[0]) {
        this.$emit('trace-selected', { traceId: items[0].trace_id });
      }
    },
  },
};
</script>

<template>
  <div>
    <h4 class="gl-display-block gl-md-display-none! gl-my-5">{{ $options.i18n.title }}</h4>

    <gl-table
      :items="formattedTraces"
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
      <template #cell(service_name)="{ item }">
        <gl-truncate :text="item.service_name" with-tooltip />
      </template>

      <template #cell(operation)="{ item }">
        <gl-truncate :text="item.operation" with-tooltip />
      </template>

      <template #empty>
        {{ $options.i18n.emptyText }}
        <gl-link @click="$emit('reload')">{{ $options.i18n.emptyLinkText }}</gl-link>
      </template>
    </gl-table>
  </div>
</template>
