import { ContentEditor } from './index';

export default {
  component: ContentEditor,
  title: 'content_editor/content_editor',
};

const Template = (_, { argTypes }) => ({
  components: { ContentEditor },
  props: Object.keys(argTypes),
  template: '<content-editor v-bind="$props" @initialized="loadContent" />',
  methods: {
    loadContent(contentEditor) {
      contentEditor.setSerializedContent('Hello content editor');
    },
  },
});

export const Default = Template.bind({});

Default.args = {
  renderMarkdown: () => '<p>Hello content editor</p>',
  uploadsPath: '/uploads/',
  serializerConfig: {},
  extensions: [],
};
