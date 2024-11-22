import EntitySelect from './entity_select.vue';

export default {
  component: EntitySelect,
  title: 'vue_shared/components/entity_select/entity_select',
};

const Template = (args, { argTypes }) => ({
  components: { EntitySelect },
  props: Object.keys(argTypes),
  template: '<EntitySelect v-bind="$props" />',
});

export const Default = Template.bind({});
Default.args = {
  block: false,
  label: 'Select a project',
  description: '',
  inputName: 'project[analytics_dashboards_pointer_attributes][target_project_id]',
  inputId: 'project_analytics_dashboards_pointer_attributes_project_id',
  initialSelection: null,
  clearable: true,
  headerText: 'Select a project',
  defaultToggleText: 'Search for project',
  toggleClass: '',
  searchable: true,
};
