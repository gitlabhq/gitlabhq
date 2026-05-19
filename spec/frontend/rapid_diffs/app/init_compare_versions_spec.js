import { createTestingPinia } from '@pinia/testing';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { initCompareVersions } from '~/rapid_diffs/app/init_compare_versions';
import { useMergeRequestVersions } from '~/merge_request/stores/merge_request_versions';

jest.mock('~/rapid_diffs/app/compare_versions/compare_versions.vue', () => ({
  name: 'CompareVersions',
  props: ['sourceVersions', 'targetVersions'],
  render(h) {
    return h('div', {
      attrs: {
        'data-compare-versions': 'true',
        'data-source-versions': JSON.stringify(this.sourceVersions),
        'data-target-versions': JSON.stringify(this.targetVersions),
      },
    });
  },
}));

jest.mock('~/rapid_diffs/app/compare_versions/commit_navigation.vue', () => ({
  name: 'CommitNavigation',
  props: ['commit'],
  render(h) {
    return h('div', {
      attrs: {
        'data-commit-navigation': 'true',
        'data-commit-id': this.commit?.id,
      },
    });
  },
}));

describe('initCompareVersions', () => {
  const sourceVersions = [
    { id: 1, version_index: 1, latest: true, selected: true },
    { id: 2, version_index: 2, latest: false, selected: false },
  ];

  const targetVersions = [
    { id: 'head', version_index: null, head: true, selected: true, branch: 'main' },
  ];

  const appData = {
    versions: { source_versions: sourceVersions, target_versions: targetVersions },
  };

  const findCompareVersions = () => document.querySelector('[data-compare-versions]');
  const findCommitNavigation = () => document.querySelector('[data-commit-navigation]');

  beforeEach(() => {
    createTestingPinia({ stubActions: false });
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  describe('version view', () => {
    it('renders CompareVersions component', () => {
      setHTMLFixture('<div data-after-browser-toggle></div>');
      initCompareVersions(document.querySelector('[data-after-browser-toggle]'), appData);

      expect(findCompareVersions()).not.toBeNull();
      expect(findCommitNavigation()).toBeNull();
    });

    it('passes versions props to component', () => {
      setHTMLFixture('<div data-after-browser-toggle></div>');
      initCompareVersions(document.querySelector('[data-after-browser-toggle]'), appData);

      const el = findCompareVersions();
      expect(JSON.parse(el.dataset.sourceVersions)).toEqual(sourceVersions);
      expect(JSON.parse(el.dataset.targetVersions)).toEqual(targetVersions);
    });
  });

  describe('commit view', () => {
    const commit = {
      id: 'abc123',
      short_id: 'abc1',
      commit_url: '/commit/abc123',
      diff_refs: { base_sha: 'p', start_sha: 'p', head_sha: 'abc123' },
    };
    const appDataWithCommit = {
      versions: { source_versions: sourceVersions, target_versions: targetVersions, commit },
    };

    it('renders CommitNavigation instead of CompareVersions', () => {
      setHTMLFixture('<div data-after-browser-toggle></div>');
      initCompareVersions(document.querySelector('[data-after-browser-toggle]'), appDataWithCommit);

      expect(findCommitNavigation()).not.toBeNull();
      expect(findCompareVersions()).toBeNull();
    });

    it('stores commit in versions store', () => {
      setHTMLFixture('<div data-after-browser-toggle></div>');
      initCompareVersions(document.querySelector('[data-after-browser-toggle]'), appDataWithCommit);

      const store = useMergeRequestVersions();
      expect(store.commit).toEqual(commit);
      expect(store.commitId).toBe('abc123');
    });
  });
});
