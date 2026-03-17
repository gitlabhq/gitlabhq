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

  describe('diffRefs', () => {
    it('combines selected source and target versions into diff refs', () => {
      store.setVersions({
        sourceVersions: [{ selected: true, base_sha: 'base000', head_sha: 'head222' }],
        targetVersions: [{ selected: true, start_sha: 'start111' }],
      });

      expect(store.diffRefs).toEqual({
        base_sha: 'base000',
        head_sha: 'head222',
        start_sha: 'start111',
      });
    });

    it('returns null when no versions are selected', () => {
      expect(store.diffRefs).toBeNull();
    });
  });
});
