import ProjectListItemDescription from './project_list_item_description.vue';

export default {
  component: ProjectListItemDescription,
  title: 'vue_shared/projects_list/projects_list_item_description',
  argTypes: {
    project: {
      control: { type: 'object' },
      description: 'Project data',
    },
  },
};

const Template = (args, { argTypes }) => ({
  components: { ProjectListItemDescription },
  props: Object.keys(argTypes),
  template: '<project-list-item-description v-bind="$props" />',
});

export const Default = Template.bind({});
Default.args = {
  project: {
    id: 1,
    archived: false,
    descriptionHtml: `<p>Eco-Track: A mobile application designed to help users reduce their carbon footprint.
    Features include personalized sustainability tips, a carbon emission calculator, and community challenges.
    Users can track their daily habits, set eco-friendly goals, and earn rewards for sustainable choices.
    The app integrates with smart home devices and local transportation data to provide real-time suggestions for energy savings and greener commutes.</p>`,
  },
};
