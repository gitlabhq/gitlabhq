import EditorModeSwitcher from './editor_mode_switcher.vue';

export default {
  component: EditorModeSwitcher,
  title: 'vue_shared/components/markdown/editor_mode_switcher',
};

const Template = (args, { argTypes }) => ({
  components: { EditorModeSwitcher },
  props: Object.keys(argTypes),
  template: '<EditorModeSwitcher v-bind="$props" />',
});

export const Default = Template.bind({});
Default.args = {
  value: 'markdown',
};
