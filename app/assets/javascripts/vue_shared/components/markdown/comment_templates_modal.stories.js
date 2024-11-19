import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { withGitLabAPIAccess } from 'storybook_addons/gitlab_api_access';

import CommentTemplatesModal from './comment_templates_modal.vue';

Vue.use(VueApollo);

export default {
  component: CommentTemplatesModal,
  title: 'vue_shared/components/markdown/comment_templates_modal',
  decorators: [withGitLabAPIAccess],
};

const Template = (args, { argTypes, createVueApollo }) => ({
  components: { CommentTemplatesModal },
  apolloProvider: createVueApollo(),
  props: Object.keys(argTypes),
  template: '<CommentTemplatesModal v-bind="$props" />',
});

export const Default = Template.bind({});
Default.args = {
  newCommentTemplatePaths: [
    {
      text: 'Your comment templates',
      href: '/-/profile/comment_templates',
    },
    {
      text: 'Project comment templates',
      href: '/qa-sandbox-136011a5d5e7/qa-test-2024-11-12-14-26-03-11787efe685f4b43/default-mr-template-project-1a6f3daa8431aae1/-/comment_templates',
    },
  ],
};
