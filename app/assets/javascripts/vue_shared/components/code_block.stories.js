import CodeBlock from './code_block.vue';

export default {
  component: CodeBlock,
  title: 'vue_shared/code_block',
};

const Template = (args, { argTypes }) => ({
  components: { CodeBlock },
  props: Object.keys(argTypes),
  template: '<code-block v-bind="$props" />',
});

export const Default = Template.bind({});
Default.args = {
  code: `git commit -a "Message"\ngit push`,
};
