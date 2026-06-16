import DataTable from './data_table.vue';
import MilestoneLink from './milestone_link.vue';

export default {
  component: MilestoneLink,
  title: 'analytics/analytics_dashboards/components/visualizations/data_table/milestone_link',
};

const Template = (args, { argTypes }) => ({
  components: { MilestoneLink },
  props: Object.keys(argTypes),
  template: `<milestone-link :title="title" :web-path="webPath" />`,
});

const TableTemplate = (args, { argTypes }) => ({
  components: { DataTable },
  props: Object.keys(argTypes),
  template: `<data-table :data="data" :options="options" />`,
});

const title = '10.0';
const webPath = 'https://gitlab.com/gitlab-org/gitlab/-/milestones/30';

export const Default = Template.bind({});
Default.args = { title, webPath };

export const InTable = TableTemplate.bind({});
InTable.args = {
  data: { nodes: [{ start: 'Aug 8, 2017', end: 'Sep 22, 2017', milestone: { title, webPath } }] },
  options: {
    fields: [
      { key: 'start', label: 'Start date' },
      { key: 'end', label: 'End date' },
      { key: 'milestone', component: 'MilestoneLink' },
    ],
  },
};
