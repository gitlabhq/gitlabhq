import { FILE_SYMLINK_MODE } from '../constants';
import FileIcon from './file_icon.vue';

export default {
  component: FileIcon,
  title: 'vue_shared/file_icon',
};

const defaultArgs = {
  fileName: 'file.log',
  folder: false,
  submodule: false,
  opened: false,
  loading: false,
};

const Template = (args, { argTypes }) => ({
  components: { FileIcon },
  props: Object.keys(argTypes),
  template: `<file-icon v-bind="$props" />`,
});

export const Default = Template.bind({});
Default.args = {
  ...defaultArgs,
};

export const Loading = Template.bind({});
Loading.args = {
  ...defaultArgs,
  loading: true,
};

export const Symlink = Template.bind({});
Symlink.args = {
  ...defaultArgs,
  fileMode: FILE_SYMLINK_MODE,
};

export const Folder = Template.bind({});
Folder.args = {
  ...defaultArgs,
  folder: true,
};
