import GroupItem from './group_item.vue';

export default {
  component: GroupItem,
  title: 'vue_shared/list_selector/group_item',
};

const Template = (args, { argTypes }) => ({
  components: { GroupItem },
  props: Object.keys(argTypes),
  template: '<group-item v-bind="$props" />',
});

export const Default = Template.bind({});
Default.args = {
  data: {
    id: '1',
    fullName: 'Gitlab Org',
    name: 'Gitlab Org',
  },
  canDelete: false,
};

export const DeletableGroup = Template.bind({});
DeletableGroup.args = {
  ...Default.args,
  canDelete: true,
};

export const HiddenGroups = Template.bind({});
HiddenGroups.args = {
  ...Default.args,
  data: {
    ...Default.args.data,
    type: 'hidden_groups',
  },
};
