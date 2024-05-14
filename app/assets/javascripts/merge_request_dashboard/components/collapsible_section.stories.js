import CollapsibleSection from './collapsible_section.vue';

const Template = (_, { argTypes }) => {
  return {
    components: { CollapsibleSection },
    props: Object.keys(argTypes),
    template: '<collapsible-section v-bind="$props">Opened</collapsible-section>',
  };
};

export default {
  component: CollapsibleSection,
  title: 'merge_requests_dashboard/collapsible_section',
};

export const Default = Template.bind({});
Default.args = { title: 'Approved', count: 3 };

export const ClosedByDefault = Template.bind({});
ClosedByDefault.args = { ...Default.args, count: 0 };
