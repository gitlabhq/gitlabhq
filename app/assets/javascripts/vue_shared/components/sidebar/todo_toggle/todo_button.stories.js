/* eslint-disable @gitlab/require-i18n-strings */

import TodoButton from './todo_button.vue';

export default {
  component: TodoButton,
  title: 'vue_shared/components/todo_toggle/todo_button',
};

const Template = (args, { argTypes }) => ({
  components: { TodoButton },
  props: Object.keys(argTypes),
  template: '<todo-button v-bind="$props" v-on="$props" />',
});

export const Default = Template.bind({});
Default.argTypes = {
  isTodo: {
    description: 'True if to-do is unresolved (i.e. not "done")',
    control: { type: 'boolean' },
  },
  click: { action: 'clicked' },
};
