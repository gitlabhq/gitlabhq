import DownloadDropdown from './download_dropdown.vue';

export default {
  component: DownloadDropdown,
  title: 'vue_shared/components/download_dropdown/download_dropdown',
};

const Template = (args, { argTypes }) => ({
  components: { DownloadDropdown },
  props: Object.keys(argTypes),
  template: '<DownloadDropdown v-bind="$props" />',
});

export const Default = Template.bind({});
Default.args = {
  downloadLinks: [
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
  downloadArtifacts: [],
  cssClass: '',
};
