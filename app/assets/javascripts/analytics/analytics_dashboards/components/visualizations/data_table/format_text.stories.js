import DataTable from './data_table.vue';
import FormatText from './format_text.vue';

export default {
  component: FormatText,
  title: 'analytics/analytics_dashboards/components/visualizations/data_table/format_text',
};

const Template = (args, { argTypes }) => ({
  components: { FormatText },
  props: Object.keys(argTypes),
  template: `<format-text :value="value" :bold="bold" />`,
});

const TableTemplate = (args, { argTypes }) => ({
  components: { DataTable },
  props: Object.keys(argTypes),
  template: `<data-table :data="data" :options="options" />`,
});

export const Default = Template.bind({});
Default.args = { value: '1.4×', bold: true };

export const InTable = TableTemplate.bind({});
InTable.args = {
  data: {
    nodes: [
      { tier: 'Light (1–4)', intensity: { value: '0.4×' } },
      { tier: 'Regular (5–24)', intensity: { value: '1.1×', bold: true } },
      { tier: 'Power (100+)', intensity: { value: '3.8×', bold: true } },
    ],
  },
  options: {
    fields: [
      { key: 'tier', label: 'Tier' },
      { key: 'intensity', label: 'Intensity', component: 'FormatText' },
    ],
  },
};
