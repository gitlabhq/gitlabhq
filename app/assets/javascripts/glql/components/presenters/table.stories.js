import { MOCK_FIELDS, MOCK_ISSUES } from 'jest/glql/mock_data';
import TablePresenter from './table.vue';
import { withTrendColumn } from './utils/table';

// A description reads off the first result row, so the metrics it quotes come from an
// aggregated query rather than the issue list the other stories use.
const TIER_FIELDS = [
  { key: 'usersCount', label: 'Users', name: 'usersCount', type: 'metric' },
  { key: 'totalCount', label: 'Sessions', name: 'totalCount', type: 'metric' },
];
const TIER_DATA = { nodes: [{ usersCount: 1747, totalCount: 18294 }] };

// Modelled on the DAP Impact "Group and project comparison" panel, which compares users.
const TREND_FIELDS = [
  { key: 'Group', label: 'Group', field: 'group', name: 'group', type: 'dimension' },
  { key: 'Project', label: 'Project', field: 'project', name: 'project', type: 'dimension' },
  { key: 'Users', label: 'Users', field: 'usersCount', name: 'usersCount', type: 'metric' },
  {
    key: 'Credits',
    label: 'Credits',
    field: 'creditsUsedSum',
    name: 'creditsUsedSum',
    type: 'metric',
  },
];

// Rows pair across periods on the dimension values' `id`.
const mockGroup = (id, path, fullName) => ({
  __typename: 'Group',
  id: `gid://gitlab/Group/${id}`,
  fullName,
  webUrl: `https://gitlab.example.com/${path}`,
});
const mockProject = (id, path, name) => ({
  __typename: 'Project',
  id: `gid://gitlab/Project/${id}`,
  name,
  nameWithNamespace: path,
  webPath: `/${path}`,
});

const PLATFORM = mockGroup(1, 'example-org/platform', 'Example Org / Platform');
const MOBILE = mockGroup(2, 'example-org/mobile', 'Example Org / Mobile');
const API = mockProject(1, 'example-org/platform/api', 'api');
const WEB_APP = mockProject(2, 'example-org/platform/web-app', 'web-app');
const IOS = mockProject(3, 'example-org/mobile/ios', 'ios');
const DOCS = mockProject(4, 'example-org/platform/docs', 'docs');

const TREND_DATA = {
  nodes: [
    { Group: PLATFORM, Project: API, Users: 18, Credits: 412.5 },
    { Group: PLATFORM, Project: WEB_APP, Users: 9, Credits: 188.25 },
    { Group: MOBILE, Project: IOS, Users: 7, Credits: 96 },
    { Group: PLATFORM, Project: DOCS, Users: 3, Credits: 12.5 },
  ],
};
// `docs` has no row here, so its change is unknown.
const TREND_COMPARISON_DATA = {
  metric: 'usersCount',
  nodes: [
    { Group: PLATFORM, Project: API, Users: 12, Credits: 301 },
    { Group: PLATFORM, Project: WEB_APP, Users: 12, Credits: 240.5 },
    { Group: MOBILE, Project: IOS, Users: 7, Credits: 88 },
  ],
};

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
    source: {
      control: 'text',
      description: 'Query data source. Decides which direction of change reads as good.',
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
    :source="source"
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

// A previous period adds a column showing how the `trendMetric` moved for each row: up,
// down, unchanged, or unknown when the project had no activity then. Sorting by it puts
// unknowns last. DataPresenter joins the column in before the table renders it.
const TREND = withTrendColumn({
  fields: TREND_FIELDS,
  data: TREND_DATA,
  comparisonData: TREND_COMPARISON_DATA,
  source: 'DuoWorkflows',
});

export const WithTrend = Template.bind({});
WithTrend.args = {
  ...Default.args,
  data: TREND.data,
  fields: TREND.fields,
  source: 'DuoWorkflows',
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
