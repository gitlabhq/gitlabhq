import NestedGroupsProjectsList from './nested_groups_projects_list.vue';
import { items } from './mock_data';

export default {
  component: NestedGroupsProjectsList,
  title: 'vue_shared/nested_groups_projects_list',
};

const Template = (args, { argTypes }) => ({
  components: { NestedGroupsProjectsList },
  props: Object.keys(argTypes),
  template: `<nested-groups-projects-list :items="items" />`,
});

export const Default = Template.bind({});
Default.args = {
  items,
};
