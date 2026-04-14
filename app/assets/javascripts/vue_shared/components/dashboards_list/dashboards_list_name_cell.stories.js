import DashboardsListNameCell from './dashboards_list_name_cell.vue';

export default {
  component: DashboardsListNameCell,
  title: 'vue_shared/components/dashboards_list/dashboards_list_name_cell',
};

const Template = (args, { argTypes }) => ({
  components: { DashboardsListNameCell },
  props: Object.keys(argTypes),
  template: `<dashboards-list-name-cell v-bind="$props" />`,
});

const defaultArgs = {
  name: 'Built in dashboard',
  description: 'Built in dashboard',
  isStarred: true,
  dashboardUrl: '/fake/link/to/share',
};

export const Default = Template.bind({});
Default.args = defaultArgs;

export const NotStarred = Template.bind({});
NotStarred.args = {
  ...defaultArgs,
  isStarred: false,
};
