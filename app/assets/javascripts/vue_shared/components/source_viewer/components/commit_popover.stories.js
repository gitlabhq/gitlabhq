import CommitPopover from './commit_popover.vue';

export default {
  component: CommitPopover,
  title: 'vue_shared/source_viewer/commit_popover',
};

const defaultCommit = {
  sha: 'abc123def456789012345678901234567890abcd',
  shortId: 'abc123de',
  title: 'Fix bug in feature flag implementation',
  authorName: 'Jane Developer',
  authoredDate: '2024-01-15T10:30:00Z',
  webPath: '/gitlab-org/gitlab/-/commit/abc123def456',
  authorGravatar:
    'https://www.gravatar.com/avatar/00000000000000000000000000000000?s=80&d=identicon',
};

const Template = (args, { argTypes }) => ({
  components: { CommitPopover },
  props: Object.keys(argTypes),
  template: `
    <div style="padding: 150px; text-align: center;">
      <a id="commit-popover-target" href="#">Hover over me to see commit popover</a>
      <commit-popover v-bind="$props" />
    </div>
  `,
});

export const Default = Template.bind({});
Default.args = {
  popoverTargetId: 'commit-popover-target',
  commit: defaultCommit,
};
