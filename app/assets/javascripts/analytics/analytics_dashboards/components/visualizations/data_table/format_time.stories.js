import DataTable from './data_table.vue';
import FormatTime from './format_time.vue';

export default {
  component: FormatTime,
  title: 'analytics/analytics_dashboards/components/visualizations/data_table/format_time',
};

const Template = (args, { argTypes }) => ({
  components: { FormatTime },
  props: Object.keys(argTypes),
  template: `<format-time :timestamp="timestamp" />`,
});

const TableTemplate = (args, { argTypes }) => ({
  components: { DataTable },
  props: Object.keys(argTypes),
  template: `<data-table :data="data" :options="options" />`,
});

export const Default = Template.bind({});
Default.args = { timestamp: '2020-03-10T12:00:00Z' };

export const InTable = TableTemplate.bind({});
InTable.args = {
  data: { nodes: [{ value: '2020-04-20', formatted: { timestamp: '2020-04-20' } }] },
  options: {
    fields: [
      { key: 'value', label: 'Raw value' },
      { key: 'formatted', label: 'Formatted Time', component: 'FormatTime' },
    ],
  },
};
