import SnippetCodeDropdown from './snippet_code_dropdown.vue';

export default {
  component: SnippetCodeDropdown,
  title: 'vue_shared/components/snippet_code_dropdown',
};

const Template = (args, { argTypes }) => ({
  components: { SnippetCodeDropdown },
  props: Object.keys(argTypes),
  template: '<clone-dropdown v-bind="$props" />',
});

const sshLink = 'ssh://some-ssh-link';
const httpLink = 'https://some-http-link';

export const Default = Template.bind({});
Default.args = {
  sshLink,
  httpLink,
};

export const HttpLink = Template.bind({});
HttpLink.args = {
  httpLink,
  sshLink: '',
};

export const SSHLink = Template.bind({});
SSHLink.args = {
  sshLink,
  httpLink: '',
};
