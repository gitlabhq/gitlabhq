import { groups } from 'jest/vue_shared/components/groups_list/mock_data';
import GroupsList from './groups_list.vue';

export default {
  component: GroupsList,
  title: 'vue_shared/groups_list',
};

const Template = (args, { argTypes }) => ({
  components: { GroupsList },
  props: Object.keys(argTypes),
  template: '<groups-list v-bind="$props" />',
});

export const Default = Template.bind({});
Default.args = {
  groups,
  showGroupIcon: true,
};
