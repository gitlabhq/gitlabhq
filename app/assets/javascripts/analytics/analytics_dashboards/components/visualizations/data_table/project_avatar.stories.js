import DataTable from './data_table.vue';
import ProjectAvatar from './project_avatar.vue';

export default {
  component: ProjectAvatar,
  title: 'analytics/analytics_dashboards/components/visualizations/data_table/project_avatar',
};

const firstChild = {
  project: {
    id: 'gid://gitlab/Project/1',
    name: 'Project One',
    avatarUrl: 'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
    webUrl: 'https://gitlab.com',
  },
  pipelineCount: 142,
};

const nodes = [
  firstChild,
  {
    project: {
      id: 'gid://gitlab/Project/2',
      name: 'Project Two',
      avatarUrl: '',
      webUrl: 'https://gitlab.com',
    },
    pipelineCount: 87,
  },
  {
    project: {
      id: 'gid://gitlab/Project/3',
      name: 'Project Three',
      avatarUrl: '',
      webUrl: 'https://gitlab.com',
    },
    pipelineCount: 23,
  },
];

const Template = (args, { argTypes }) => ({
  components: { ProjectAvatar },
  props: Object.keys(argTypes),
  template: `<project-avatar v-bind="$props" />`,
});

const TableTemplate = (args, { argTypes }) => ({
  components: { DataTable },
  props: Object.keys(argTypes),
  template: `<data-table :data="data" :options="options" />`,
});

export const Default = Template.bind({});
Default.args = { ...firstChild.project };

export const InTable = TableTemplate.bind({});
InTable.args = {
  data: {
    nodes,
  },
  options: {
    fields: [
      { key: 'project', label: 'Project', component: 'ProjectAvatar' },
      { key: 'pipelineCount', label: 'Pipelines' },
    ],
  },
};
