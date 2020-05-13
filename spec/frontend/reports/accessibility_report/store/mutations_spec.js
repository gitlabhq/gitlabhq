import mutations from '~/reports/accessibility_report/store/mutations';
import createStore from '~/reports/accessibility_report/store';

describe('Accessibility Reports mutations', () => {
  let localState;
  let localStore;

  beforeEach(() => {
    localStore = createStore();
    localState = localStore.state;
  });

  describe('SET_ENDPOINT', () => {
    it('sets endpoint to given value', () => {
      const endpoint = 'endpoint.json';
      mutations.SET_ENDPOINT(localState, endpoint);

      expect(localState.endpoint).toEqual(endpoint);
    });
  });

  describe('REQUEST_REPORT', () => {
    it('sets isLoading to true', () => {
      mutations.REQUEST_REPORT(localState);

      expect(localState.isLoading).toEqual(true);
    });
  });

  describe('RECEIVE_REPORT_SUCCESS', () => {
    it('sets isLoading to false', () => {
      mutations.RECEIVE_REPORT_SUCCESS(localState, {});

      expect(localState.isLoading).toEqual(false);
    });

    it('sets hasError to false', () => {
      mutations.RECEIVE_REPORT_SUCCESS(localState, {});

      expect(localState.hasError).toEqual(false);
    });

    it('sets report to response report', () => {
      const report = { data: 'testing' };
      mutations.RECEIVE_REPORT_SUCCESS(localState, report);

      expect(localState.report).toEqual(report);
    });
  });

  describe('RECEIVE_REPORT_ERROR', () => {
    it('sets isLoading to false', () => {
      mutations.RECEIVE_REPORT_ERROR(localState);

      expect(localState.isLoading).toEqual(false);
    });

    it('sets hasError to true', () => {
      mutations.RECEIVE_REPORT_ERROR(localState);

      expect(localState.hasError).toEqual(true);
    });
  });
});
