import DataTable from './data_table.vue';
import CalculateSum from './calculate_sum.vue';

const data = [
  [10, 20, 30],
  [5, -3, 25],
];

export default {
  component: CalculateSum,
  title: 'analytics/analytics_dashboards/components/visualizations/data_table/calculate_sum',
};

const Template = (args, { argTypes }) => ({
  components: { CalculateSum },
  props: Object.keys(argTypes),
  template: '<calculate-sum v-bind="$props" />',
});

export const Default = Template.bind({});
Default.args = {
  values: data[0],
};

const InTableTemplate = (args, { argTypes }) => ({
  components: { DataTable },
  props: Object.keys(argTypes),
  template: '<data-table v-bind="$props" />',
});

export const InTable = InTableTemplate.bind({});
InTable.args = {
  data: {
    nodes: [
      {
        label: `Summing: ${data[0].join(' + ')}`,
        total: { values: data[0] },
      },
      {
        label: `Summing: ${data[1].join(' + ')}`,
        total: { values: data[1] },
      },
    ],
  },
  options: {
    fields: [{ key: 'label' }, { key: 'total', label: 'Sum', component: 'CalculateSum' }],
  },
};
