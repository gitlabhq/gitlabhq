import {
  MOCK_AGGREGATED_DATA_ONE_DIM,
  MOCK_AGGREGATED_FIELDS_ONE_DIM_ONE_METRIC,
  MOCK_AGGREGATED_FIELDS_ONE_DIM_TWO_METRICS,
  MOCK_AGGREGATED_FIELDS_TWO_DIMS_ONE_METRIC,
} from 'jest/glql/mock_data';
import LineChart from './line_chart.vue';

export default {
  component: LineChart,
  title: 'glql/components/presenters/line_chart',
  argTypes: {
    data: { control: false, description: 'Aggregated query result, as `{ nodes: [] }`.' },
    fields: { control: false, description: 'Dimension and metric fields the query selected.' },
    loading: { control: 'boolean' },

    // events
    error: { action: 'error' },
  },
};

const Template = (args, { argTypes }) => ({
  components: { LineChart },
  props: Object.keys(argTypes),
  template: `<line-chart
    :data="data"
    :fields="fields"
    :loading="loading"
    v-on="{ error }"
  />`,
});

export const Default = Template.bind({});
Default.args = {
  data: MOCK_AGGREGATED_DATA_ONE_DIM,
  fields: MOCK_AGGREGATED_FIELDS_ONE_DIM_ONE_METRIC,
  loading: false,
};

// One dimension plots a series per metric.
export const TwoMetrics = Template.bind({});
TwoMetrics.args = {
  ...Default.args,
  fields: MOCK_AGGREGATED_FIELDS_ONE_DIM_TWO_METRICS,
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

// A line chart takes at most one dimension, so a second one is a block authoring error.
// The embedded view shows it as an alert; here it lands in the Actions panel.
export const ValidationError = Template.bind({});
ValidationError.args = {
  ...Default.args,
  fields: MOCK_AGGREGATED_FIELDS_TWO_DIMS_ONE_METRIC,
};
