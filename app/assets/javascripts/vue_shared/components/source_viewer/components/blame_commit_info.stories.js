import BlameCommitInfo from './blame_commit_info.vue';

export default {
  component: BlameCommitInfo,
  title: 'vue_shared/source_viewer/blame_commit_info',
};

const defaultCommit = {
  sha: 'abc123def456789012345678901234567890abcd',
  shortId: 'abc123de',
  title: 'Fix bug in feature flag implementation',
  message: 'Fix bug in feature flag implementation\n\nThis commit addresses the issue where...',
  authorName: 'Jane Developer',
  authoredDate: '2024-01-15T10:30:00Z',
  committedDate: '2024-01-15T10:30:00Z',
  webPath: '/gitlab-org/gitlab/-/commit/abc123def456',
  authorGravatar:
    'https://www.gravatar.com/avatar/00000000000000000000000000000000?s=80&d=identicon',
  parentSha: 'parent123456789',
};

const defaultAuthor = {
  id: 'gid://gitlab/User/1',
  username: 'jdeveloper',
  name: 'Jane Developer',
  webPath: '/jdeveloper',
  avatarUrl: 'https://www.gravatar.com/avatar/00000000000000000000000000000000?s=80&d=identicon',
};

const defaultArgs = {
  commit: defaultCommit,
  previousPath: 'app/models/user.rb',
  projectPath: 'gitlab-org/gitlab',
};

const Template = (args, { argTypes }) => ({
  components: { BlameCommitInfo },
  props: Object.keys(argTypes),
  template: `
    <div style="padding: 20px; max-width: 600px;">
      <blame-commit-info v-bind="$props" />
    </div>
  `,
});

export const Default = Template.bind({});
Default.args = {
  ...defaultArgs,
};

export const WithAuthorLink = Template.bind({});
WithAuthorLink.args = {
  ...defaultArgs,
  commit: {
    ...defaultCommit,
    author: defaultAuthor,
  },
};

export const LongCommitTitle = Template.bind({});
LongCommitTitle.args = {
  ...defaultArgs,
  commit: {
    ...defaultCommit,
    title:
      'Refactor authentication module to support multiple OAuth providers and improve error handling for edge cases in the login flow with additional context',
  },
};
