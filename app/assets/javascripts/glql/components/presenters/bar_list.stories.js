import {
  MOCK_AGGREGATED_DATA_ONE_DIM,
  MOCK_AGGREGATED_FIELDS_ONE_DIM_ONE_METRIC,
  MOCK_AGGREGATED_FIELDS_TWO_DIMS_ONE_METRIC,
} from 'jest/glql/mock_data';
import BarList from './bar_list.vue';

// The shape the DAP Impact MR cycle time panels use: two quantiles plus a merged count.
const QUANTILE_FIELDS = [
  { key: 'Median', field: 'timeToMergeQuantile', label: 'Median', type: 'metric' },
  { key: 'p75', field: 'timeToMergeQuantile', label: 'p75', type: 'metric' },
  { key: 'throughputCount', field: 'throughputCount', label: 'Merged', type: 'metric' },
];

// 9h 24m and 23h, in seconds.
const QUANTILES = { nodes: [{ Median: 33840, p75: 82800, throughputCount: 2362 }] };

export default {
  component: BarList,
  title: 'glql/components/presenters/bar_list',
  argTypes: {
    data: { control: false, description: 'Aggregated query result, as `{ nodes: [] }`.' },
    fields: { control: false, description: 'Dimension and metric fields the query selected.' },
    loading: { control: 'boolean' },
    displayConfig: {
      control: 'object',
      description: 'Block `displayConfig`, e.g. `maxRows`, `description`, `hiddenMetrics`.',
    },

    // events
    error: { action: 'error' },
  },
};

const Template = (args, { argTypes }) => ({
  components: { BarList },
  props: Object.keys(argTypes),
  template: `<bar-list
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

// A tail of one row is left alone, so three rows need a cap of one to roll up.
export const WithOtherRow = Template.bind({});
WithOtherRow.args = {
  ...Default.args,
  displayConfig: { maxRows: 1 },
};

// Shares divide by the grand total, so an all-zero result renders rows at zero length
// rather than dividing by zero.
export const ZeroTotal = Template.bind({});
ZeroTotal.args = {
  ...Default.args,
  data: {
    nodes: [
      { language: 'ruby', totalCount: 0 },
      { language: 'go', totalCount: 0 },
    ],
  },
};

// Without a dimension each metric becomes a bar, so a metric that only the description
// quotes has to be named in `hiddenMetrics` to stay out of them.
export const WithDescription = Template.bind({});
WithDescription.args = {
  ...Default.args,
  data: QUANTILES,
  fields: QUANTILE_FIELDS,
  displayConfig: {
    description: '%{throughputCount} merged merge requests',
    hiddenMetrics: ['throughputCount'],
  },
};

export const NoData = Template.bind({});
NoData.args = {
  ...Default.args,
  data: { nodes: [] },
};

export const Loading = Template.bind({});
Loading.args = {
  ...Default.args,
  loading: true,
};

// A second dimension has nowhere to render, so the presenter emits an error instead of
// a chart. The embedded view shows it as an alert; here it lands in the Actions panel.
export const ValidationError = Template.bind({});
ValidationError.args = {
  ...Default.args,
  fields: MOCK_AGGREGATED_FIELDS_TWO_DIMS_ONE_METRIC,
};
