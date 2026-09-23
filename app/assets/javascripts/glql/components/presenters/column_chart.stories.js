import {
  MOCK_AGGREGATED_DATA_ONE_DIM,
  MOCK_AGGREGATED_DATA_TWO_DIMS,
  MOCK_AGGREGATED_FIELDS_ONE_DIM_ONE_METRIC,
  MOCK_AGGREGATED_FIELDS_ONE_DIM_TWO_METRICS,
  MOCK_AGGREGATED_FIELDS_TWO_DIMS_ONE_METRIC,
} from 'jest/glql/mock_data';
import ColumnChart from './column_chart.vue';

export default {
  component: ColumnChart,
  title: 'glql/components/presenters/column_chart',
  argTypes: {
    data: { control: false, description: 'Aggregated query result, as `{ nodes: [] }`.' },
    fields: { control: false, description: 'Dimension and metric fields the query selected.' },
    loading: { control: 'boolean' },
    displayConfig: { control: 'object', description: 'Block `displayConfig`.' },

    // events
    error: { action: 'error' },
  },
};

const Template = (args, { argTypes }) => ({
  components: { ColumnChart },
  props: Object.keys(argTypes),
  template: `<column-chart
    :data="data"
    :fields="fields"
    :loading="loading"
    :display-config="displayConfig"
    v-on="{ error }"
  />`,
});

export const Default = Template.bind({});
Default.args = {
  data: MOCK_AGGREGATED_DATA_ONE_DIM,
  fields: MOCK_AGGREGATED_FIELDS_ONE_DIM_ONE_METRIC,
  loading: false,
  displayConfig: {},
};

// One dimension plots a series per metric.
export const TwoMetrics = Template.bind({});
TwoMetrics.args = {
  ...Default.args,
  fields: MOCK_AGGREGATED_FIELDS_ONE_DIM_TWO_METRICS,
};

// Stacking has no visible effect on a single metric, so it pairs with two.
export const Stacked = Template.bind({});
Stacked.args = {
  ...TwoMetrics.args,
  displayConfig: { stacked: true },
};

// A second dimension becomes the series, which is why only one metric fits.
export const TwoDimensions = Template.bind({});
TwoDimensions.args = {
  ...Default.args,
  data: MOCK_AGGREGATED_DATA_TWO_DIMS,
  fields: MOCK_AGGREGATED_FIELDS_TWO_DIMS_ONE_METRIC,
};

export const Loading = Template.bind({});
Loading.args = {
  ...Default.args,
  loading: true,
};

export const NoData = Template.bind({});
NoData.args = {
  ...Default.args,
  data: { nodes: [] },
};
// An empty chart still renders an ECharts `role="img"` container, but with no
// data there is nothing for ECharts to describe it with.
NoData.parameters = {
  a11y: { config: { rules: [{ id: 'role-img-alt', enabled: false }] } },
};
