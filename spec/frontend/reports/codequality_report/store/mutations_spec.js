import mutations from '~/reports/codequality_report/store/mutations';
import createStore from '~/reports/codequality_report/store';

describe('Codequality Reports mutations', () => {
  let localState;
  let localStore;

  beforeEach(() => {
    localStore = createStore();
    localState = localStore.state;
  });

  describe('SET_PATHS', () => {
    it('sets paths to given values', () => {
      const basePath = 'base.json';
      const headPath = 'head.json';
      const baseBlobPath = 'base/blob/path/';
      const headBlobPath = 'head/blob/path/';
      const helpPath = 'help.html';

      mutations.SET_PATHS(localState, {
        basePath,
        headPath,
        baseBlobPath,
        headBlobPath,
        helpPath,
      });

      expect(localState.basePath).toEqual(basePath);
      expect(localState.headPath).toEqual(headPath);
      expect(localState.baseBlobPath).toEqual(baseBlobPath);
      expect(localState.headBlobPath).toEqual(headBlobPath);
      expect(localState.helpPath).toEqual(helpPath);
    });
  });

  describe('REQUEST_REPORTS', () => {
    it('sets isLoading to true', () => {
      mutations.REQUEST_REPORTS(localState);

      expect(localState.isLoading).toEqual(true);
    });
  });

  describe('RECEIVE_REPORTS_SUCCESS', () => {
    it('sets isLoading to false', () => {
      mutations.RECEIVE_REPORTS_SUCCESS(localState, {});

      expect(localState.isLoading).toEqual(false);
    });

    it('sets hasError to false', () => {
      mutations.RECEIVE_REPORTS_SUCCESS(localState, {});

      expect(localState.hasError).toEqual(false);
    });

    it('sets newIssues and resolvedIssues from response data', () => {
      const data = { newIssues: [{ id: 1 }], resolvedIssues: [{ id: 2 }] };
      mutations.RECEIVE_REPORTS_SUCCESS(localState, data);

      expect(localState.newIssues).toEqual(data.newIssues);
      expect(localState.resolvedIssues).toEqual(data.resolvedIssues);
    });
  });

  describe('RECEIVE_REPORTS_ERROR', () => {
    it('sets isLoading to false', () => {
      mutations.RECEIVE_REPORTS_ERROR(localState);

      expect(localState.isLoading).toEqual(false);
    });

    it('sets hasError to true', () => {
      mutations.RECEIVE_REPORTS_ERROR(localState);

      expect(localState.hasError).toEqual(true);
    });
  });
});
