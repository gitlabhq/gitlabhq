import { createTestingPinia } from '@pinia/testing';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { initCommitWidget } from '~/rapid_diffs/app/init_commit_widget';
import { useMergeRequestVersions } from '~/merge_request/stores/merge_request_versions';

jest.mock('~/diffs/components/commit_widget.vue', () => ({
  name: 'CommitWidget',
  props: ['commit', 'collapsible'],
  render(h) {
    return h('div', {
      attrs: {
        'data-testid': 'commit-widget',
        'data-commit-id': this.commit?.id,
        'data-collapsible': String(this.collapsible),
      },
    });
  },
}));

const findEl = () => document.querySelector('[data-commit-widget]');
const findWidget = () => document.querySelector('[data-testid="commit-widget"]');

describe('initCommitWidget', () => {
  const commit = { id: 'abc123', title: 'Fix bug', short_id: 'abc1' };

  beforeEach(() => {
    setHTMLFixture('<div data-commit-widget></div>');

    createTestingPinia({ stubActions: false });
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  it('does not render CommitWidget when the store has no commit', () => {
    initCommitWidget(findEl());

    expect(findWidget()).toBeNull();
  });

  it('renders CommitWidget when the store has a commit', () => {
    useMergeRequestVersions().setCommit(commit);

    initCommitWidget(findEl());

    expect(findWidget()).not.toBeNull();
    expect(findWidget().dataset.commitId).toBe('abc123');
  });

  it('passes collapsible=false to CommitWidget', () => {
    useMergeRequestVersions().setCommit(commit);

    initCommitWidget(findEl());

    expect(findWidget().dataset.collapsible).toBe('false');
  });
});
