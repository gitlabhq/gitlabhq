import { withGitLabAPIAccess } from 'storybook_addons/gitlab_api_access';
import Api from '~/api';
import { ContentEditor } from './index';

export default {
  component: ContentEditor,
  title: 'ce/content_editor/content_editor',
  decorators: [withGitLabAPIAccess],
};

const Template = (_, { argTypes }) => ({
  components: { ContentEditor },
  props: Object.keys(argTypes),
  template: `
    <content-editor v-bind="$props" />
  `,
});

export const Default = Template.bind({});

Default.args = {
  project: 'gitlab-org/gitlab-shell',
  renderMarkdown: async (text) => {
    const response = await Api.markdown({ text, gfm: true, project: Default.args.project });

    return response.data.html;
  },
  markdown: 'This is **bold text**',
  uploadsPath: '/uploads/',
  serializerConfig: {},
  extensions: [],
  enableAutocomplete: false,
  markdownDocsPath: 'fake/path',
};
