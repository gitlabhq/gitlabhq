import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import { TEST_HOST } from 'spec/test_constants';
import axios from '~/lib/utils/axios_utils';
import createStore from '~/reports/accessibility_report/store';
import * as actions from '~/reports/accessibility_report/store/actions';
import * as types from '~/reports/accessibility_report/store/mutation_types';
import { mockReport } from '../mock_data';

describe('Accessibility Reports actions', () => {
  let localState;
  let localStore;

  beforeEach(() => {
    localStore = createStore();
    localState = localStore.state;
  });

  describe('setEndpoints', () => {
    it('should commit SET_ENDPOINTS mutation', () => {
      const endpoint = 'endpoint.json';

      return testAction(
        actions.setEndpoint,
        endpoint,
        localState,
        [{ type: types.SET_ENDPOINT, payload: endpoint }],
        [],
      );
    });
  });

  describe('fetchReport', () => {
    let mock;

    beforeEach(() => {
      localState.endpoint = `${TEST_HOST}/endpoint.json`;
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
      actions.stopPolling();
      actions.clearEtagPoll();
    });

    describe('success', () => {
      it('should commit REQUEST_REPORT mutation and dispatch receiveReportSuccess', () => {
        const data = { report: { summary: {} } };
        mock.onGet(`${TEST_HOST}/endpoint.json`).reply(200, data);

        return testAction(
          actions.fetchReport,
          null,
          localState,
          [{ type: types.REQUEST_REPORT }],
          [
            {
              payload: { status: 200, data },
              type: 'receiveReportSuccess',
            },
          ],
        );
      });
    });

    describe('error', () => {
      it('should commit REQUEST_REPORT and RECEIVE_REPORT_ERROR mutations', () => {
        mock.onGet(`${TEST_HOST}/endpoint.json`).reply(500);

        return testAction(
          actions.fetchReport,
          null,
          localState,
          [{ type: types.REQUEST_REPORT }],
          [{ type: 'receiveReportError' }],
        );
      });
    });
  });

  describe('receiveReportSuccess', () => {
    it('should commit RECEIVE_REPORT_SUCCESS mutation with 200', () => {
      return testAction(
        actions.receiveReportSuccess,
        { status: 200, data: mockReport },
        localState,
        [{ type: types.RECEIVE_REPORT_SUCCESS, payload: mockReport }],
        [{ type: 'stopPolling' }],
      );
    });

    it('should not commit RECEIVE_REPORTS_SUCCESS mutation with 204', () => {
      return testAction(
        actions.receiveReportSuccess,
        { status: 204, data: mockReport },
        localState,
        [],
        [],
      );
    });
  });

  describe('receiveReportError', () => {
    it('should commit RECEIVE_REPORT_ERROR mutation', () => {
      return testAction(
        actions.receiveReportError,
        null,
        localState,
        [{ type: types.RECEIVE_REPORT_ERROR }],
        [{ type: 'stopPolling' }],
      );
    });
  });
});
