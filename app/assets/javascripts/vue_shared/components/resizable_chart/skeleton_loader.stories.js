import SkeletonLoader from './skeleton_loader.vue';
import {
  DEFAULT_RX,
  DEFAULT_BAR_WIDTH,
  DEFAULT_LABEL_WIDTH,
  DEFAULT_LABEL_HEIGHT,
} from './constants';

export default {
  component: SkeletonLoader,
  title: 'vue_shared/components/resizable_chart/skeleton_loader',
  argTypes: {
    barWidth: {
      control: { type: 'range', min: 1, max: 11, step: 1 },
      description: 'Width of each bar, as a percentage of the chart width.',
    },
    labelWidth: {
      control: { type: 'number', min: 0 },
      description: 'Width of each x-axis label, as a percentage of the chart width.',
    },
    labelHeight: {
      control: { type: 'number', min: 0 },
      description: 'Height of each x-axis label, as a percentage of the chart height.',
    },
    rx: {
      control: { type: 'number', min: 0, step: 0.1 },
      description: 'Corner radius of the bars and labels, as a percentage.',
    },
    uniqueKey: { control: false },
  },
};

const Template = (args, { argTypes }) => ({
  components: { SkeletonLoader },
  props: Object.keys(argTypes),
  template: '<skeleton-loader v-bind="$props" />',
});

export const Default = Template.bind({});
Default.args = {
  barWidth: DEFAULT_BAR_WIDTH,
  labelWidth: DEFAULT_LABEL_WIDTH,
  labelHeight: DEFAULT_LABEL_HEIGHT,
  rx: DEFAULT_RX,
};

export const CustomDimensions = Template.bind({});
CustomDimensions.args = {
  barWidth: 3,
  labelWidth: 7,
  labelHeight: 2,
  rx: 0.6,
};
