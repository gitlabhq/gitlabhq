import CodeDropdownItem from './code_dropdown_item.vue';

export default {
  component: CodeDropdownItem,
  title: 'vue_shared/components/code_dropdown/code_dropdown_item',
};

const Template = (args, { argTypes }) => ({
  components: { CodeDropdownItem },
  props: Object.keys(argTypes),
  template: '<CodeDropdownItem v-bind="$props" />',
});

export const Default = Template.bind({});
Default.args = {
  label: 'Clone with SSH',
  labelClass: '!gl-text-sm !gl-pt-2',
  link: 'ssh://git@127.0.0.1:2222/qa-sandbox-7fc0a48405b3/qa-test-2024-11-12-14-26-03-3201237323e90ab2/email-notification-test-4540cb4c2dd3f297.git',
  inputId: 'copy-ssh-url-input',
  name: 'ssh_project_clone',
  testId: 'copy-ssh-url-button',
};
