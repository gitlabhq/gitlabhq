import { __ } from '~/locale';
import DropdownWidget from './dropdown_widget.vue';

export default {
  component: DropdownWidget,
  title: 'vue_shared/dropdown/dropdown_widget/dropdown_widget',
};

const Template = (args, { argTypes }) => ({
  components: { DropdownWidget },
  props: Object.keys(argTypes),
  template: '<dropdown-widget v-bind="$props" v-on="$props" />',
});

export const Default = Template.bind({});
Default.args = {
  options: [
    { id: 'gid://gitlab/Milestone/-1', title: __('Any Milestone') },
    { id: 'gid://gitlab/Milestone/0', title: __('No Milestone') },
    { id: 'gid://gitlab/Milestone/-2', title: __('Upcoming') },
    { id: 'gid://gitlab/Milestone/-3', title: __('Started') },
  ],
  selectText: 'Select',
  searchText: 'Search',
};
