import ClipboardButton from './clipboard_button.vue';

export default {
  component: ClipboardButton,
  title: 'vue_shared/components/clipboard_button',
};

const Template = (args, { argTypes }) => ({
  components: { ClipboardButton },
  props: Object.keys(argTypes),
  template: '<ClipboardButton v-bind="$props" />',
});

export const Default = Template.bind({});
Default.args = {
  text: 'qa-test-feature-356134266df1ef7f',
  gfm: null,
  title: 'Copy branch name <kbd aria-hidden="true" class="flat gl-ml-1">b</kbd>',
  tooltipPlacement: 'bottom',
  tooltipContainer: false,
  tooltipBoundary: null,
  cssClass: null,
  category: 'tertiary',
  size: 'small',
  variant: 'default',
};
