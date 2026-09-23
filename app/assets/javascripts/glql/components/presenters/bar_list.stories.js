import {
  MOCK_AGGREGATED_DATA_ONE_DIM,
  MOCK_AGGREGATED_FIELDS_ONE_DIM_ONE_METRIC,
  MOCK_AGGREGATED_FIELDS_TWO_DIMS_ONE_METRIC,
} from 'jest/glql/mock_data';
import BarList from './bar_list.vue';

export default {
  component: BarList,
  title: 'glql/components/presenters/bar_list',
  argTypes: {
    data: { control: false, description: 'Aggregated query result, as `{ nodes: [] }`.' },
    fields: { control: false, description: 'Dimension and metric fields the query selected.' },
    loading: { control: 'boolean' },
    displayConfig: { control: 'object', description: 'Block `displayConfig`, e.g. `maxRows`.' },

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

// Six rows is the default cap, so a rollup needs either more rows or a lower cap.
export const WithOtherRow = Template.bind({});
WithOtherRow.args = {
  ...Default.args,
  displayConfig: { maxRows: 2 },
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
