import FileRow from './file_row.vue';

export default {
  component: FileRow,
  title: 'vue_shared/file_row',
};

const defaultFile = {
  name: 'environment.log',
  type: 'blob',
};

const defaultArgs = {
  file: {
    ...defaultFile,
  },
  fileUrl: 'https://project.com/files/file.log',
  level: 1,
};

const Template = (args, { argTypes }) => ({
  components: { FileRow },
  props: Object.keys(argTypes),
  template: `<file-row v-bind="$props" />`,
});

export const Blob = Template.bind({});
Blob.args = {
  ...defaultArgs,
};

export const Loading = Template.bind({});
Loading.args = {
  ...defaultArgs,
  file: {
    ...defaultFile,
    loading: true,
  },
};

export const Tree = Template.bind({});
Tree.args = {
  ...defaultArgs,
  file: {
    name: 'files',
    type: 'tree',
  },
};

export const OpenFolder = Template.bind({});
OpenFolder.args = {
  ...defaultArgs,
  file: {
    name: 'files',
    type: 'tree',
    opened: true,
    active: true,
  },
};
