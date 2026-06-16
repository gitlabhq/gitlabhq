import DataTable from './data_table.vue';
import MetricLabel from './metric_label.vue';

export default {
  component: MetricLabel,
  title: 'analytics/analytics_dashboards/components/visualizations/data_table/metric_label',
};

const Template = (args, { argTypes }) => ({
  components: { MetricLabel },
  props: Object.keys(argTypes),
  template: `<metric-label :identifier="identifier" :requestPath="requestPath" :is-project="isProject" :tracking-property="trackingProperty" />`,
});

const TableTemplate = (args, { argTypes }) => ({
  components: { DataTable },
  props: Object.keys(argTypes),
  template: `<data-table :data="data" :options="options" />`,
});

const metric = { identifier: 'cycle_time', requestPath: 'some/path/for/request', isProject: false };

export const Default = Template.bind({});
Default.args = { ...metric };

export const InTable = TableTemplate.bind({});
InTable.args = {
  data: { nodes: [{ metric, value: '12.5/d' }] },
  options: {
    fields: [
      { key: 'metric', label: 'Metric', component: 'MetricLabel' },
      { key: 'value', label: 'Current value' },
    ],
  },
};
