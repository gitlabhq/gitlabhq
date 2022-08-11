import mutations from '~/ide/stores/mutations/merge_request';
import state from '~/ide/stores/state';

describe('IDE store merge request mutations', () => {
  let localState;

  beforeEach(() => {
    localState = state();
    localState.projects = { abcproject: { mergeRequests: {} } };

    mutations.SET_MERGE_REQUEST(localState, {
      projectPath: 'abcproject',
      mergeRequestId: 1,
      mergeRequest: {
        title: 'mr',
      },
    });
  });

  describe('SET_CURRENT_MERGE_REQUEST', () => {
    it('sets current merge request', () => {
      mutations.SET_CURRENT_MERGE_REQUEST(localState, 2);

      expect(localState.currentMergeRequestId).toBe(2);
    });
  });

  describe('SET_MERGE_REQUEST', () => {
    it('setsmerge request data', () => {
      const newMr = localState.projects.abcproject.mergeRequests[1];

      expect(newMr.title).toBe('mr');
      expect(newMr.active).toBe(true);
    });

    it('keeps original data', () => {
      const versions = ['change'];
      const mergeRequest = localState.projects.abcproject.mergeRequests[1];

      mergeRequest.versions = versions;

      mutations.SET_MERGE_REQUEST(localState, {
        projectPath: 'abcproject',
        mergeRequestId: 1,
        mergeRequest: {
          title: ['change'],
        },
      });

      expect(mergeRequest.title).toBe('mr');
      expect(mergeRequest.versions).toEqual(versions);
    });
  });

  describe('SET_MERGE_REQUEST_CHANGES', () => {
    it('sets merge request changes', () => {
      mutations.SET_MERGE_REQUEST_CHANGES(localState, {
        projectPath: 'abcproject',
        mergeRequestId: 1,
        changes: {
          diff: 'abc',
        },
      });

      const newMr = localState.projects.abcproject.mergeRequests[1];

      expect(newMr.changes.diff).toBe('abc');
    });
  });

  describe('SET_MERGE_REQUEST_VERSIONS', () => {
    it('sets merge request versions', () => {
      mutations.SET_MERGE_REQUEST_VERSIONS(localState, {
        projectPath: 'abcproject',
        mergeRequestId: 1,
        versions: [{ id: 123 }],
      });

      const newMr = localState.projects.abcproject.mergeRequests[1];

      expect(newMr.versions.length).toBe(1);
      expect(newMr.versions[0].id).toBe(123);
    });
  });
});
