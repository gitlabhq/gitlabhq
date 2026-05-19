import createMockApollo from 'helpers/mock_apollo_helper';
import savedRepliesQuery from 'ee_else_ce/vue_shared/components/markdown/saved_replies.query.graphql';
import CommentTemplatesModal from './comment_templates_modal.vue';

const MOCK_SAVED_REPLIES = [
  {
    id: 'gid://gitlab/SavedReply/1',
    name: 'Thanks',
    content: 'Thank you for your contribution!',
  },
  {
    id: 'gid://gitlab/SavedReply/2',
    name: 'LGTM',
    content: 'Looks good to me! :+1:',
  },
  {
    id: 'gid://gitlab/SavedReply/3',
    name: 'Needs work',
    content: 'This needs some additional work before it can be merged.',
  },
];

export default {
  component: CommentTemplatesModal,
  title: 'vue_shared/markdown/comment_templates_modal',
};

const Template = (args, { argTypes }) => ({
  components: { CommentTemplatesModal },
  apolloProvider: createMockApollo([
    [
      savedRepliesQuery,
      () =>
        Promise.resolve({
          data: {
            currentUser: {
              id: 'gid://gitlab/User/1',
              savedReplies: {
                nodes: MOCK_SAVED_REPLIES,
              },
            },
          },
        }),
    ],
  ]),
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
      href: '/gitlab-org/gitlab/-/comment_templates',
    },
  ],
};
