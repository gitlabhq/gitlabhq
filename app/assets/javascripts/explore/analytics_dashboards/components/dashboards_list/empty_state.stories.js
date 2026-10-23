import EmptyState from './empty_state.vue';

export default {
  component: EmptyState,
  title: 'explore/analytics_dashboards/components/dashboards_list/empty_state',
};

const Template = (args, { argTypes }) => ({
  components: { EmptyState },
  props: Object.keys(argTypes),
  template: `<empty-state v-bind="$props" />`,
});

const defaultArgs = {};

export const Default = Template.bind({});
Default.args = defaultArgs;
