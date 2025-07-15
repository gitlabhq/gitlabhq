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
  time: new Date().getTime() - 60e3 * 60 * 24 * 2,
  tooltipPlacement: 'top',
  cssClass: '',
  dateTimeFormat: 'asDateTime',
  enableTruncation: false,
};
