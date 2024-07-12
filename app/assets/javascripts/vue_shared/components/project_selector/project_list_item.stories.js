import ProjectListItem from './project_list_item.vue';

export default {
  component: ProjectListItem,
  title: 'vue_shared/project_selector/project_list_item',
};

const Template = (args, { argTypes }) => ({
  components: { ProjectListItem },
  props: Object.keys(argTypes),
  template: '<project-list-item v-bind="$props" />',
});

export const Default = Template.bind({});
Default.args = {
  project: {
    id: 1,
    name: 'MyProject',
    name_with_namespace: 'path / to / MyProject',
  },
  selected: false,
};

export const SelectedProject = Template.bind({});
SelectedProject.args = {
  ...Default.args,
  selected: true,
};

export const MatchedProject = Template.bind({});
MatchedProject.args = {
  ...Default.args,
  matcher: 'proj',
};
