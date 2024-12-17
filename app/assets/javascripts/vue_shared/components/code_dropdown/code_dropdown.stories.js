import CodeDropdown from './code_dropdown.vue';

export default {
  component: CodeDropdown,
  title: 'vue_shared/components/code_dropdown/code_dropdown',
};

const Template = (args, { argTypes }) => ({
  components: { CodeDropdown },
  props: Object.keys(argTypes),
  template: '<CodeDropdown v-bind="$props" />',
});

export const Default = Template.bind({});
Default.args = {
  sshUrl:
    'ssh://git@127.0.0.1:2222/qa-sandbox-562a63b00e52/qa-test-2024-11-12-14-26-03-0ba21e9be21b0f92/project-with-code-9d53f643766c6edc.git',
  httpUrl:
    'http://127.0.0.1:3000/qa-sandbox-562a63b00e52/qa-test-2024-11-12-14-26-03-0ba21e9be21b0f92/project-with-code-9d53f643766c6edc.git',
  kerberosUrl: '',
  xcodeUrl: '',
  currentPath: null,
  directoryDownloadLinks: [
    {
      text: 'zip',
      path: '/qa-sandbox-562a63b00e52/qa-test-2024-11-12-14-26-03-0ba21e9be21b0f92/project-with-code-9d53f643766c6edc/-/archive/main/project-with-code-9d53f643766c6edc-main.zip',
    },
    {
      text: 'tar.gz',
      path: '/qa-sandbox-562a63b00e52/qa-test-2024-11-12-14-26-03-0ba21e9be21b0f92/project-with-code-9d53f643766c6edc/-/archive/main/project-with-code-9d53f643766c6edc-main.tar.gz',
    },
    {
      text: 'tar.bz2',
      path: '/qa-sandbox-562a63b00e52/qa-test-2024-11-12-14-26-03-0ba21e9be21b0f92/project-with-code-9d53f643766c6edc/-/archive/main/project-with-code-9d53f643766c6edc-main.tar.bz2',
    },
    {
      text: 'tar',
      path: '/qa-sandbox-562a63b00e52/qa-test-2024-11-12-14-26-03-0ba21e9be21b0f92/project-with-code-9d53f643766c6edc/-/archive/main/project-with-code-9d53f643766c6edc-main.tar',
    },
  ],
};
