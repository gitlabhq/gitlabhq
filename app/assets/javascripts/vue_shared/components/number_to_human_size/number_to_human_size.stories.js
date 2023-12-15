import NumberToHumanSize from './number_to_human_size.vue';

export default {
  component: NumberToHumanSize,
  title: 'vue_shared/number_to_human_size',
};

const Template = (args, { argTypes }) => ({
  components: { NumberToHumanSize },
  props: Object.keys(argTypes),
  template: '<number-to-human-size v-bind="$props" />',
});

export const Default = Template.bind({});
Default.args = {
  value: 42.55 * 1024 * 1024 * 1024,
  fractionDigits: 1,
  labelClass: '',
  plainZero: false,
};

export const PlainZero = Template.bind({});
PlainZero.args = {
  ...Default.args,
  value: 0,
  plainZero: true,
};

export const CustomStyles = Template.bind({});
CustomStyles.args = {
  ...Default.args,
  class: 'gl-font-weight-bold',
  labelClass: 'gl-font-sm gl-text-gray-500',
};
