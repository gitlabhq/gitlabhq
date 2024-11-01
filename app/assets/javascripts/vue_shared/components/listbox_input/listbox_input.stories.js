import ListboxInput from './listbox_input.vue';

export default {
  component: ListboxInput,
  title: 'vue_shared/listbox_input',
};

const Template = (args, { argTypes }) => ({
  components: { ListboxInput },
  props: Object.keys(argTypes),
  template: '<listbox-input v-model="selected" v-bind="$props" />',
});

const defaultProps = {
  name: 'input_name',
  defaultToggleText: 'Select an option',
  items: [
    { text: 'Option 1', value: '1' },
    { text: 'Option 2', value: '2' },
    { text: 'Option 3', value: '3' },
  ],
  selected: null,
};

export const Default = Template.bind({});
Default.args = defaultProps;

export const Disabled = Template.bind({});
Disabled.args = {
  ...defaultProps,
  disabled: true,
};

export const WithLabel = Template.bind({});
WithLabel.args = {
  ...defaultProps,
  description: 'A nice label',
};

export const WithDescription = Template.bind({});
WithDescription.args = {
  ...defaultProps,
  description: 'This is a collapsible list',
};

export const WithSelectedOption = Template.bind({});
WithSelectedOption.args = {
  ...defaultProps,
  selected: '2',
};
