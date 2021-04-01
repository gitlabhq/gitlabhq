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
    it('should commit SET_PATHS mutation', (done) => {
      testAction(
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
        done,
      );
    });
  });

  describe('requestReports', () => {
    it('should commit REQUEST_REPORTS mutation', (done) => {
      testAction(requestReports, null, mockedState, [{ type: types.REQUEST_REPORTS }], [], done);
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
      it('dispatches requestReports and receiveReportsSuccess ', (done) => {
        mock
          .onGet(`${TEST_HOST}/endpoint.json`)
          .replyOnce(200, { summary: {}, suites: [{ name: 'rspec' }] });

        testAction(
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
          done,
        );
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onGet(`${TEST_HOST}/endpoint.json`).reply(500);
      });

      it('dispatches requestReports and receiveReportsError ', (done) => {
        testAction(
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
          done,
        );
      });
    });
  });

  describe('receiveReportsSuccess', () => {
    it('should commit RECEIVE_REPORTS_SUCCESS mutation with 200', (done) => {
      testAction(
        receiveReportsSuccess,
        { data: { summary: {} }, status: 200 },
        mockedState,
        [{ type: types.RECEIVE_REPORTS_SUCCESS, payload: { summary: {} } }],
        [],
        done,
      );
    });

    it('should not commit RECEIVE_REPORTS_SUCCESS mutation with 204', (done) => {
      testAction(
        receiveReportsSuccess,
        { data: { summary: {} }, status: 204 },
        mockedState,
        [],
        [],
        done,
      );
    });
  });

  describe('receiveReportsError', () => {
    it('should commit RECEIVE_REPORTS_ERROR mutation', (done) => {
      testAction(
        receiveReportsError,
        null,
        mockedState,
        [{ type: types.RECEIVE_REPORTS_ERROR }],
        [],
        done,
      );
    });
  });

  describe('openModal', () => {
    it('should commit SET_ISSUE_MODAL_DATA', (done) => {
      testAction(
        openModal,
        { name: 'foo' },
        mockedState,
        [{ type: types.SET_ISSUE_MODAL_DATA, payload: { name: 'foo' } }],
        [],
        done,
      );
    });
  });

  describe('closeModal', () => {
    it('should commit RESET_ISSUE_MODAL_DATA', (done) => {
      testAction(
        closeModal,
        {},
        mockedState,
        [{ type: types.RESET_ISSUE_MODAL_DATA, payload: {} }],
        [],
        done,
      );
    });
  });
});
