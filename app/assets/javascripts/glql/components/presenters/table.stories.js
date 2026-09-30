import { MOCK_FIELDS, MOCK_ISSUES } from 'jest/glql/mock_data';
import TablePresenter from './table.vue';

// A description reads off the first result row, so the metrics it quotes come from an
// aggregated query rather than the issue list the other stories use.
const TIER_FIELDS = [
  { key: 'usersCount', label: 'Users', name: 'usersCount', type: 'metric' },
  { key: 'totalCount', label: 'Sessions', name: 'totalCount', type: 'metric' },
];
const TIER_DATA = { nodes: [{ usersCount: 1747, totalCount: 18294 }] };

export default {
  component: TablePresenter,
  title: 'glql/components/presenters/table',
  argTypes: {
    data: { control: false, description: 'Query result, as `{ nodes: [] }`.' },
    fields: { control: false, description: 'Fields the query selected, one column each.' },
    loading: {
      control: 'boolean',
      description: 'Boolean, or the number of skeleton rows to render.',
    },
    displayConfig: {
      control: 'object',
      description: 'Block `displayConfig`, e.g. `description`.',
    },
  },
};

const Template = (args, { argTypes }) => ({
  components: { TablePresenter },
  props: Object.keys(argTypes),
  template: `<table-presenter
    :data="data"
    :fields="fields"
    :loading="loading"
    :display-config="displayConfig"
  />`,
});

// Click a column header to sort by it.
export const Default = Template.bind({});
Default.args = {
  data: MOCK_ISSUES,
  fields: MOCK_FIELDS,
  loading: false,
  displayConfig: {},
};

// `%{metricName}` placeholders resolve against the first row, each formatted in its own
// metric's unit.
export const WithDescription = Template.bind({});
WithDescription.args = {
  ...Default.args,
  data: TIER_DATA,
  fields: TIER_FIELDS,
  displayConfig: {
    description: '%{usersCount} users ran %{totalCount} sessions',
  },
};

// Skeleton rows sit under the rows already loaded, which is how a "load more" reads.
export const LoadingMore = Template.bind({});
LoadingMore.args = {
  ...Default.args,
  loading: true,
};

// A number sets how many skeleton rows to render, so the placeholder matches the
// page size that is on its way.
export const LoadingFirstPage = Template.bind({});
LoadingFirstPage.args = {
  ...Default.args,
  data: { nodes: [] },
  loading: 3,
};

// Headers still render, so the columns a query selected stay visible.
export const NoData = Template.bind({});
NoData.args = {
  ...Default.args,
  data: { nodes: [] },
};
