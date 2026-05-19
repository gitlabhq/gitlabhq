import { createTestingPinia } from '@pinia/testing';
import { useMergeRequestVersions } from '~/merge_request/stores/merge_request_versions';

describe('mergeRequestVersions store', () => {
  let store;

  beforeEach(() => {
    createTestingPinia({ stubActions: false });
    store = useMergeRequestVersions();
  });

  describe('setVersions', () => {
    it('sets source and target versions', () => {
      const sourceVersions = [{ id: 1, selected: true }];
      const targetVersions = [{ id: 2, selected: true }];

      store.setVersions({ sourceVersions, targetVersions });

      expect(store.sourceVersions).toEqual(sourceVersions);
      expect(store.targetVersions).toEqual(targetVersions);
    });
  });

  describe('setCommit', () => {
    it('stores the commit object', () => {
      const commit = {
        id: 'abc123',
        short_id: 'abc1',
        commit_url: '/commit/abc123',
        diff_refs: { base_sha: 'parent', start_sha: 'parent', head_sha: 'abc123' },
      };

      store.setCommit(commit);

      expect(store.commit).toEqual(commit);
    });
  });

  describe('selectedSourceVersion', () => {
    it('returns the selected source version', () => {
      store.setVersions({
        sourceVersions: [
          { id: 1, selected: false },
          { id: 2, selected: true, head_sha: 'head', base_sha: 'base' },
        ],
        targetVersions: [],
      });

      expect(store.selectedSourceVersion).toEqual(
        expect.objectContaining({ id: 2, head_sha: 'head', base_sha: 'base' }),
      );
    });

    it('returns undefined when no version is selected', () => {
      store.setVersions({ sourceVersions: [{ id: 1, selected: false }], targetVersions: [] });

      expect(store.selectedSourceVersion).toBeUndefined();
    });
  });

  describe('selectedTargetVersion', () => {
    it('returns the selected target version', () => {
      store.setVersions({
        sourceVersions: [],
        targetVersions: [{ id: 1, selected: true, start_sha: 'start' }],
      });

      expect(store.selectedTargetVersion).toEqual(
        expect.objectContaining({ id: 1, start_sha: 'start' }),
      );
    });
  });

  describe('commitId', () => {
    it('returns null when no commit', () => {
      expect(store.commitId).toBeNull();
    });

    it('returns the commit id', () => {
      store.setCommit({ id: 'abc123', diff_refs: {} });

      expect(store.commitId).toBe('abc123');
    });
  });

  describe('diffRefs', () => {
    it('uses target refs when target is head', () => {
      store.setVersions({
        sourceVersions: [{ selected: true, base_sha: 'base000', head_sha: 'head222' }],
        targetVersions: [
          { selected: true, head: true, start_sha: 'start111', head_sha: 'target_head' },
        ],
      });

      expect(store.diffRefs).toEqual({
        base_sha: 'start111',
        head_sha: 'target_head',
        start_sha: 'start111',
      });
    });

    it('uses target start_sha when comparing against a specific target version', () => {
      store.setVersions({
        sourceVersions: [{ selected: true, base_sha: 'base000', head_sha: 'head222' }],
        targetVersions: [{ selected: true, head: false, version_index: 2, start_sha: 'start111' }],
      });

      expect(store.diffRefs).toEqual({
        base_sha: 'base000',
        head_sha: 'head222',
        start_sha: 'start111',
      });
    });

    it('uses source base_sha as start_sha in the default "compare with master" view', () => {
      store.setVersions({
        sourceVersions: [{ selected: true, base_sha: 'base000', head_sha: 'head222' }],
        targetVersions: [
          { selected: true, head: false, version_index: null, start_sha: 'master_tip' },
        ],
      });

      expect(store.diffRefs).toEqual({
        base_sha: 'base000',
        head_sha: 'head222',
        start_sha: 'base000',
      });
    });

    it('returns null when no versions are selected', () => {
      expect(store.diffRefs).toBeNull();
    });

    it('returns commit diff_refs when in commit view', () => {
      const commitDiffRefs = { base_sha: 'parent', start_sha: 'parent', head_sha: 'sha' };

      store.setVersions({
        sourceVersions: [{ selected: true, base_sha: 'base000', head_sha: 'head222' }],
        targetVersions: [{ selected: true, start_sha: 'start111' }],
      });
      store.setCommit({ id: 'sha', diff_refs: commitDiffRefs });

      expect(store.diffRefs).toEqual(commitDiffRefs);
    });
  });
});
