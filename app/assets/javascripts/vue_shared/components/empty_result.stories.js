import EmptyResult, { TYPES } from './empty_result.vue';

export default {
  component: EmptyResult,
  title: 'vue_shared/empty_result',
  argTypes: {
    type: {
      control: 'select',
      options: Object.values(TYPES),
    },
  },
};

const Template = (args, { argTypes }) => ({
  components: { EmptyResult },
  props: Object.keys(argTypes),
  template: `<empty-result v-bind="$props" />`,
});

export const Default = Template.bind({});
Default.args = {
  type: TYPES.search,
};
