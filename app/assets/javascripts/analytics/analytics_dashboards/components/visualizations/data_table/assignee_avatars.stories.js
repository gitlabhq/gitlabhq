import DataTable from './data_table.vue';
import AssigneeAvatars from './assignee_avatars.vue';

export default {
  component: AssigneeAvatars,
  title: 'analytics/analytics_dashboards/components/visualizations/data_table/assignee_avatars',
};

const nodes = [
  {
    name: 'Thing 1',
    webUrl: 'https://gitlab.com',
    avatarUrl: 'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
  },
  {
    name: 'Thing 2',
    webUrl: 'https://gitlab.com',
    avatarUrl:
      'https://www.gravatar.com/avatar/c4ab964b90c3049c47882b319d3c5cc0?s=80\u0026d=identicon',
  },
  {
    name: 'Administrator',
    webUrl: 'https://gitlab.com',
    avatarUrl: 'https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon',
  },
];

const Template = (args, { argTypes }) => ({
  components: { AssigneeAvatars },
  props: Object.keys(argTypes),
  template: `<assignee-avatars :nodes="nodes" />`,
});

const TableTemplate = (args, { argTypes }) => ({
  components: { DataTable },
  props: Object.keys(argTypes),
  template: `<data-table :data="data" :options="options" />`,
});

export const Default = Template.bind({});
Default.args = { nodes };

export const InTable = TableTemplate.bind({});
InTable.args = {
  data: {
    nodes: [
      {
        title: 'No assignees',
        assignees: { nodes: [] },
      },
      {
        title: 'Single assignee',
        assignees: { nodes: nodes.slice(0, 1) },
      },
      {
        title: 'Multiple assignee',
        assignees: { nodes },
      },
    ],
  },
  options: {
    fields: [
      { key: 'title' },
      { key: 'assignees', label: 'Assignees', component: 'AssigneeAvatars' },
    ],
  },
};
