import TimeAgoTooltip from './time_ago_tooltip.vue';

export default {
  component: TimeAgoTooltip,
  title: 'vue_shared/components/time_ago_tooltip',
};

const Template = (args, { argTypes }) => ({
  components: { TimeAgoTooltip },
  props: Object.keys(argTypes),
  template: '<TimeAgoTooltip v-bind="$props" />',
});

export const Default = Template.bind({});
Default.args = {
  time: '2024-11-18T17:39:57.000+00:00',
  tooltipPlacement: 'top',
  cssClass: '',
  dateTimeFormat: 'asDateTime',
  enableTruncation: false,
};
