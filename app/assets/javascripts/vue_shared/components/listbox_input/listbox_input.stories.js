import ListboxInput from './listbox_input.vue';

export default {
  component: ListboxInput,
  title: 'vue_shared/listbox_input',
};

const Template = (args, { argTypes }) => ({
  components: { ListboxInput },
  data() {
    return { selected: null };
  },
  props: Object.keys(argTypes),
  template: '<listbox-input v-model="selected" v-bind="$props" />',
});

export const Default = Template.bind({});
Default.args = {
  name: 'input_name',
  defaultToggleText: 'Select an option',
  items: [
    { text: 'Option 1', value: '1' },
    { text: 'Option 2', value: '2' },
    { text: 'Option 3', value: '3' },
  ],
};
