import DataTable from './data_table.vue';
import FormatTimeRange from './format_time_range.vue';

export default {
  component: FormatTimeRange,
  title: 'analytics/analytics_dashboards/components/visualizations/data_table/format_time_range',
};

const Template = (args, { argTypes }) => ({
  components: { FormatTimeRange },
  props: Object.keys(argTypes),
  template: `<format-time-range :start-timestamp="startTimestamp" :end-timestamp="endTimestamp" />`,
});

const TableTemplate = (args, { argTypes }) => ({
  components: { DataTable },
  props: Object.keys(argTypes),
  template: `<data-table :data="data" :options="options" />`,
});

export const Default = Template.bind({});
Default.args = {
  startTimestamp: '2020-01-01',
  endTimestamp: '2020-06-01',
};

const createTableRow = (startTimestamp, endTimestamp) => ({
  startTimestamp,
  endTimestamp,
  range: {
    startTimestamp,
    endTimestamp,
  },
});

export const InTable = TableTemplate.bind({});
InTable.args = {
  data: {
    nodes: [
      createTableRow('2020-01-01T00:00:00Z', '2020-01-01T00:00:01Z'),
      createTableRow('2020-01-01T00:00:00Z', '2020-01-01T00:01:00Z'),
      createTableRow('2020-01-01T00:00:00Z', '2020-01-01T00:05:00Z'),
      createTableRow('2020-01-01T00:00:00Z', '2020-01-01T02:00:00Z'),
      createTableRow('2020-01-01', '2020-01-02'),
      createTableRow('2020-01-01', '2020-02-01'),
    ],
  },
  options: {
    fields: [
      { key: 'startTimestamp', label: 'Start timestamp' },
      { key: 'endTimestamp', label: 'End timestamp' },
      { key: 'range', label: 'Time range', component: 'FormatTimeRange' },
    ],
  },
};
