import createStore from '~/ci/reports/codequality_report/store';
import mutations from '~/ci/reports/codequality_report/store/mutations';
import { STATUS_NOT_FOUND } from '~/ci/reports/constants';

describe('Codequality Reports mutations', () => {
  let localState;
  let localStore;

  beforeEach(() => {
    localStore = createStore();
    localState = localStore.state;
  });

  describe('SET_PATHS', () => {
    it('sets paths to given values', () => {
      const baseBlobPath = 'base/blob/path/';
      const headBlobPath = 'head/blob/path/';
      const reportsPath = 'reports.json';
      const helpPath = 'help.html';

      mutations.SET_PATHS(localState, {
        baseBlobPath,
        headBlobPath,
        reportsPath,
        helpPath,
      });

      expect(localState.baseBlobPath).toEqual(baseBlobPath);
      expect(localState.headBlobPath).toEqual(headBlobPath);
      expect(localState.reportsPath).toEqual(reportsPath);
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

    it('clears status and statusReason', () => {
      mutations.RECEIVE_REPORTS_SUCCESS(localState, {});

      expect(localState.status).toEqual('');
      expect(localState.statusReason).toEqual('');
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

    it('sets status based on error object', () => {
      const error = { status: STATUS_NOT_FOUND };
      mutations.RECEIVE_REPORTS_ERROR(localState, error);

      expect(localState.status).toEqual(error.status);
    });

    it('sets statusReason to string from error response data', () => {
      const data = { status_reason: 'This merge request does not have codequality reports' };
      const error = { response: { data } };
      mutations.RECEIVE_REPORTS_ERROR(localState, error);

      expect(localState.statusReason).toEqual(data.status_reason);
    });
  });
});
