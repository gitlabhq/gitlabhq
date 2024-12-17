import ProjectSelect from './project_select.vue';

export default {
  component: ProjectSelect,
  title: 'vue_shared/components/entity_select/project_select',
};

const Template = (args, { argTypes }) => ({
  components: { ProjectSelect },
  provide: {
    groupId: 'groupId',
    fullPath: 'gitlab-org',
  },
  props: Object.keys(argTypes),
  template: '<ProjectSelect v-bind="$props" />',
});

export const Default = Template.bind({});
Default.args = {
  block: false,
  label: 'Select a project',
  hasHtmlLabel: false,
  inputName: 'project[analytics_dashboards_pointer_attributes][target_project_id]',
  inputId: 'project_analytics_dashboards_pointer_attributes_project_id',
  groupId: '524',
  userId: null,
  withShared: true,
  includeSubgroups: true,
  membership: false,
  orderBy: 'last_activity_at',
  initialSelection: null,
  emptyText: 'Search for project',
};
