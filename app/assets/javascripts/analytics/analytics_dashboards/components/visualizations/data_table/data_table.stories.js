import DashboardLayout from 'storybook_helpers/dashboards/dashboard_layout.vue';
import { TREND_STYLE_DESC } from '~/analytics/dashboards/constants';
import DataTable from './data_table.vue';

export default {
  component: DataTable,
  title: 'analytics/analytics_dashboards/components/visualizations/data_table/data_table',
};

const Template = (args, { argTypes }) => ({
  components: { DataTable, DashboardLayout },
  props: Object.keys(argTypes),
  template: `<data-table :data="data" :options="options" :query="query" />`,
});

const WithDashboard = (args, { argTypes }) => ({
  components: { DataTable, DashboardLayout },
  props: Object.keys(argTypes),
  template: `
      <dashboard-layout :panels="panelsConfig">
        <data-table :data="data" :options="options" :query="query" />
      </dashboard-layout>`,
});

const changePercentData = [
  { value: 0 },
  { value: -0.4 },
  { value: 0.12 },
  { value: 0.14, trendStyle: TREND_STYLE_DESC },
];

const data = {
  nodes: [
    {
      title: 'MR 0',
      additions: 1,
      deletions: 0,
      commitCount: 1,
      userNotesCount: 1,
    },
    {
      title: 'MR 1',
      additions: 1,
      deletions: 0,
      commitCount: 1,
      userNotesCount: 1,
    },
    {
      title: 'MR 2',
      additions: 4,
      deletions: 3,
      commitCount: 10,
      userNotesCount: 1,
    },
    {
      title: 'MR 3',
      additions: 20,
      deletions: 4,
      commitCount: 40,
      userNotesCount: 1,
    },
  ],
};

const defaultArgs = { data };

export const Default = Template.bind({});
Default.args = defaultArgs;

export const WithPagination = Template.bind({});
WithPagination.args = {
  data: {
    ...data,
    pageInfo: {
      hasNextPage: true,
    },
  },
};

export const WithSorting = Template.bind({});
WithSorting.args = {
  data,
  query: { sortBy: 'title', sortDesc: true },
  options: {
    fields: [
      { key: 'title', sortable: true },
      { key: 'additions', sortable: true },
      { key: 'deletions', sortable: true },
      { key: 'commitCount' },
      { key: 'userNotesCount' },
    ],
  },
};

export const InDashboardPanel = WithDashboard.bind({});
InDashboardPanel.args = {
  ...defaultArgs,
  panelsConfig: [
    {
      id: '1',
      title: 'Awesome data table',
      gridAttributes: {
        yPos: 0,
        xPos: 0,
        width: 9,
        height: 3,
      },
    },
  ],
};

// See https://bootstrap-vue.org/docs/components/table#fields-as-an-array-of-objects
export const CustomFields = Template.bind({});
CustomFields.parameters = {
  docs: {
    description: {
      story:
        'Custom field components may be used to change the render format of a column of the table. The example below uses the `AssigneeAvatars` and `DiffLineChanges` custom field components. Any additional examples can be found within the `data_table/` folder.',
    },
  },
};

CustomFields.args = {
  data: {
    nodes: data.nodes.map(({ title, additions, deletions }, idx) => ({
      title,
      assignees: {
        nodes: [
          {
            name: 'Administrator',
            webUrl: 'https://gitlab.com',
            avatarUrl:
              'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
          },
        ],
      },
      changes: {
        additions,
        deletions,
      },
      change: changePercentData[idx] ?? changePercentData[0],
    })),
  },
  options: {
    fields: [
      { key: 'title' },
      { key: 'assignees', label: 'Assignees', component: 'AssigneeAvatars' },
      { key: 'changes', label: 'Diff', component: 'DiffLineChanges' },
      { key: 'change', label: '+/- %', component: 'ChangePercentageIndicator' },
    ],
  },
};
