import CloneCodeDropdown from './clone_code_dropdown.vue';

export default {
  component: CloneCodeDropdown,
  title: 'vue_shared/components/clone_code_dropdown',
};

const Template = (args, { argTypes }) => ({
  components: { CloneCodeDropdown },
  props: Object.keys(argTypes),
  template: '<clone-code-dropdown v-bind="$props" />',
});

const sshUrl = 'ssh://some-ssh-link';
const httpLink = 'https://some-http-link';

export const Default = Template.bind({});
Default.args = {
  sshUrl,
  httpUrl: httpLink,
};
