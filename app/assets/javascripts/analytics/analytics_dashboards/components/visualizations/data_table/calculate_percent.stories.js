import DataTable from './data_table.vue';
import CalculatePercent from './calculate_percent.vue';

export default {
  component: CalculatePercent,
  title: 'analytics/analytics_dashboards/components/visualizations/data_table/calculate_percent',
};

const Template = (args, { argTypes }) => ({
  components: { CalculatePercent },
  props: Object.keys(argTypes),
  template: `<calculate-percent :numerator="numerator" :denominator="denominator" :variant="variant" />`,
});

const TableTemplate = (args, { argTypes }) => ({
  components: { DataTable },
  props: Object.keys(argTypes),
  template: `<data-table :data="data" :options="options" />`,
});

export const Default = Template.bind({});
Default.args = {
  numerator: 30,
  denominator: 40,
};

// The numerator reads at full size with its share beside it, which is how a table shows a count
// and how much of the total it accounts for in one column.
export const NumeratorWithPercent = Template.bind({});
NumeratorWithPercent.args = {
  numerator: 30,
  denominator: 40,
  variant: 'NUMERATOR_WITH_PERCENT',
};

export const InTable = TableTemplate.bind({});
InTable.args = {
  data: {
    nodes: [
      {
        value: '2020-04-20',
        rate: {
          numerator: 30,
          denominator: 40,
        },
      },
    ],
  },
  options: {
    fields: [
      { key: 'value', label: 'Raw value' },
      { key: 'rate', label: 'Rate %', component: 'CalculatePercent' },
    ],
  },
};
