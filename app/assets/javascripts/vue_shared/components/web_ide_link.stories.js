import WebIdeLink from './web_ide_link.vue';

export default {
  component: WebIdeLink,
  title: 'vue_shared/web_ide_link',
};

const Template = (args, { argTypes }) => ({
  components: { WebIdeLink },
  props: Object.keys(argTypes),
  template: `
    <web-ide-link v-bind="$props" class="gl-w-12">
    </web-ide-link>
  `,
});

export const Default = Template.bind({});
export const Blob = Template.bind({});
export const WithButtonVariant = Template.bind({});

const defaultArgs = {
  isFork: false,
  needsToFork: false,
  gitpodEnabled: true,
  showEditButton: true,
  showWebIdeButton: true,
  showGitpodButton: true,
  showPipelineEditorButton: true,
  disableForkModal: true,
};

Default.args = {
  ...defaultArgs,
};

Blob.args = {
  ...defaultArgs,
  isBlob: true,
};

WithButtonVariant.args = {
  ...defaultArgs,
  buttonVariant: 'confirm',
};
