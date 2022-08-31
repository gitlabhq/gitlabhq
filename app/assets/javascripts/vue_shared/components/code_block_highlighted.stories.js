import CodeBlockHighlighted from './code_block_highlighted.vue';

export default {
  component: CodeBlockHighlighted,
  title: 'vue_shared/code_block_highlighted',
};

const Template = (args, { argTypes }) => ({
  components: { CodeBlockHighlighted },
  props: Object.keys(argTypes),
  template: '<code-block-highlighted v-bind="$props" />',
});

export const Default = Template.bind({});
Default.args = {
  code: `const foo = 1;\nconsole.log(foo + ' yay')`,
  language: 'javascript',
};
