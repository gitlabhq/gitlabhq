import {
  MOCK_AGGREGATED_DATA_ONE_DIM,
  MOCK_AGGREGATED_FIELDS_ONE_DIM_ONE_METRIC,
  MOCK_AGGREGATED_FIELDS_ONE_DIM_TWO_METRICS,
  MOCK_AGGREGATED_FIELDS_TWO_DIMS_ONE_METRIC,
} from 'jest/glql/mock_data';
import DivergingBarChart from './diverging_bar_chart.vue';

export default {
  component: DivergingBarChart,
  title: 'glql/components/presenters/diverging_bar_chart',
  argTypes: {
    data: { control: false, description: 'Aggregated query result, as `{ nodes: [] }`.' },
    fields: {
      control: false,
      description: 'Dimension and metric fields the query selected.',
    },
    loading: { control: 'boolean' },

    // events
    error: { action: 'error' },
  },
};

const Template = (args, { argTypes }) => ({
  components: { DivergingBarChart },
  props: Object.keys(argTypes),
  template: `<diverging-bar-chart
    :data="data"
    :fields="fields"
    :loading="loading"
    v-on="{ error }"
  />`,
});

// The first metric grows left from the centre, the second grows right.
export const Default = Template.bind({});
Default.args = {
  data: MOCK_AGGREGATED_DATA_ONE_DIM,
  fields: MOCK_AGGREGATED_FIELDS_ONE_DIM_TWO_METRICS,
  loading: false,
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

// Fields arrive after the first render, so an empty set draws nothing and is
// not yet an error.
export const AwaitingFields = Template.bind({});
AwaitingFields.args = {
  ...Default.args,
  fields: [],
};

// The two halves are a pair, so anything but two metrics emits an error and
// draws nothing rather than half a chart.
export const OneMetric = Template.bind({});
OneMetric.args = {
  ...Default.args,
  fields: MOCK_AGGREGATED_FIELDS_ONE_DIM_ONE_METRIC,
};

export const TwoDimensions = Template.bind({});
TwoDimensions.args = {
  ...Default.args,
  fields: MOCK_AGGREGATED_FIELDS_TWO_DIMS_ONE_METRIC,
};
