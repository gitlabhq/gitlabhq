import ListItemDescription from '~/vue_shared/components/resource_lists/list_item_description.vue';

export default {
  component: ListItemDescription,
  title: 'vue_shared/resource_lists/list_item_description',
  argTypes: {
    resource: {
      control: { type: 'object' },
      description: 'Resource data',
    },
  },
};

const Template = (args, { argTypes }) => ({
  components: { ListItemDescription },
  props: Object.keys(argTypes),
  template: '<list-item-description v-bind="$props" />',
});

export const Default = Template.bind({});
Default.args = {
  resource: {
    id: 1,
    archived: false,
    descriptionHtml: `<p>Eco-Track: A mobile application designed to help users reduce their carbon footprint.
    Features include personalized sustainability tips, a carbon emission calculator, and community challenges.
    Users can track their daily habits, set eco-friendly goals, and earn rewards for sustainable choices.
    The app integrates with smart home devices and local transportation data to provide real-time suggestions for energy savings and greener commutes.</p>`,
  },
};

export const PendingDeletion = Template.bind({});
PendingDeletion.args = {
  ...Default.args,
  resource: {
    ...Default.args.resource,
    markedForDeletionOn: '2024-12-01',
    permanentDeletionDate: '2024-12-07',
  },
};
