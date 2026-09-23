import {
  MOCK_AGGREGATED_DATA_ONE_DIM,
  MOCK_AGGREGATED_DATA_TWO_DIMS,
  MOCK_AGGREGATED_FIELDS_ONE_DIM_ONE_METRIC,
  MOCK_AGGREGATED_FIELDS_TWO_DIMS_ONE_METRIC,
} from 'jest/glql/mock_data';
import HeatMap from './heat_map.vue';

export default {
  component: HeatMap,
  title: 'glql/components/presenters/heat_map',
  argTypes: {
    data: { control: false, description: 'Aggregated query result, as `{ nodes: [] }`.' },
    fields: { control: false, description: 'Must be exactly two dimensions and one metric.' },
    loading: { control: 'boolean' },
    displayConfig: { control: 'object', description: 'Block `displayConfig`, e.g. `description`.' },

    // events
    error: { action: 'error' },
  },
};

const Template = (args, { argTypes }) => ({
  components: { HeatMap },
  props: Object.keys(argTypes),
  template: `<heat-map
    :data="data"
    :fields="fields"
    :loading="loading"
    :display-config="displayConfig"
    v-on="{ error }"
  />`,
});

// The first dimension becomes the columns and the second the rows.
export const Default = Template.bind({});
Default.args = {
  data: MOCK_AGGREGATED_DATA_TWO_DIMS,
  fields: MOCK_AGGREGATED_FIELDS_TWO_DIMS_ONE_METRIC,
  loading: false,
  displayConfig: {},
};

export const WithDescription = Template.bind({});
WithDescription.args = {
  ...Default.args,
  displayConfig: { description: 'Code suggestions accepted per user and language' },
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

// A heat map needs both axes, so a single dimension is a block authoring error.
// The embedded view shows it as an alert; here it lands in the Actions panel.
export const ValidationError = Template.bind({});
ValidationError.args = {
  ...Default.args,
  data: MOCK_AGGREGATED_DATA_ONE_DIM,
  fields: MOCK_AGGREGATED_FIELDS_ONE_DIM_ONE_METRIC,
};
