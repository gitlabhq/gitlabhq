import MockAdapter from 'axios-mock-adapter';
import { TEST_HOST } from 'helpers/test_constants';
import testAction from 'helpers/vuex_action_helper';
import axios from '~/lib/utils/axios_utils';
import {
  setPaths,
  requestReports,
  fetchReports,
  stopPolling,
  clearEtagPoll,
  receiveReportsSuccess,
  receiveReportsError,
  openModal,
  closeModal,
} from '~/reports/grouped_test_report/store/actions';
import * as types from '~/reports/grouped_test_report/store/mutation_types';
import state from '~/reports/grouped_test_report/store/state';

describe('Reports Store Actions', () => {
  let mockedState;

  beforeEach(() => {
    mockedState = state();
  });

  describe('setPaths', () => {
    it('should commit SET_PATHS mutation', () => {
      return testAction(
        setPaths,
        { endpoint: 'endpoint.json', headBlobPath: '/blob/path' },
        mockedState,
        [
          {
            type: types.SET_PATHS,
            payload: { endpoint: 'endpoint.json', headBlobPath: '/blob/path' },
          },
        ],
        [],
      );
    });
  });

  describe('requestReports', () => {
    it('should commit REQUEST_REPORTS mutation', () => {
      return testAction(requestReports, null, mockedState, [{ type: types.REQUEST_REPORTS }], []);
    });
  });

  describe('fetchReports', () => {
    let mock;

    beforeEach(() => {
      mockedState.endpoint = `${TEST_HOST}/endpoint.json`;
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
      stopPolling();
      clearEtagPoll();
    });

    describe('success', () => {
      it('dispatches requestReports and receiveReportsSuccess', () => {
        mock
          .onGet(`${TEST_HOST}/endpoint.json`)
          .replyOnce(200, { summary: {}, suites: [{ name: 'rspec' }] });

        return testAction(
          fetchReports,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestReports',
            },
            {
              payload: { data: { summary: {}, suites: [{ name: 'rspec' }] }, status: 200 },
              type: 'receiveReportsSuccess',
            },
          ],
        );
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onGet(`${TEST_HOST}/endpoint.json`).reply(500);
      });

      it('dispatches requestReports and receiveReportsError', () => {
        return testAction(
          fetchReports,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestReports',
            },
            {
              type: 'receiveReportsError',
            },
          ],
        );
      });
    });
  });

  describe('receiveReportsSuccess', () => {
    it('should commit RECEIVE_REPORTS_SUCCESS mutation with 200', () => {
      return testAction(
        receiveReportsSuccess,
        { data: { summary: {} }, status: 200 },
        mockedState,
        [{ type: types.RECEIVE_REPORTS_SUCCESS, payload: { summary: {} } }],
        [],
      );
    });

    it('should not commit RECEIVE_REPORTS_SUCCESS mutation with 204', () => {
      return testAction(
        receiveReportsSuccess,
        { data: { summary: {} }, status: 204 },
        mockedState,
        [],
        [],
      );
    });
  });

  describe('receiveReportsError', () => {
    it('should commit RECEIVE_REPORTS_ERROR mutation', () => {
      return testAction(
        receiveReportsError,
        null,
        mockedState,
        [{ type: types.RECEIVE_REPORTS_ERROR }],
        [],
      );
    });
  });

  describe('openModal', () => {
    it('should commit SET_ISSUE_MODAL_DATA', () => {
      return testAction(
        openModal,
        { name: 'foo' },
        mockedState,
        [{ type: types.SET_ISSUE_MODAL_DATA, payload: { name: 'foo' } }],
        [],
      );
    });
  });

  describe('closeModal', () => {
    it('should commit RESET_ISSUE_MODAL_DATA', () => {
      return testAction(
        closeModal,
        {},
        mockedState,
        [{ type: types.RESET_ISSUE_MODAL_DATA, payload: {} }],
        [],
      );
    });
  });
});
