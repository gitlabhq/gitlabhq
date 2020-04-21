import axios from '~/lib/utils/axios_utils';
import MockAdapter from 'axios-mock-adapter';
import * as actions from '~/reports/accessibility_report/store/actions';
import * as types from '~/reports/accessibility_report/store/mutation_types';
import createStore from '~/reports/accessibility_report/store';
import { TEST_HOST } from 'spec/test_constants';
import testAction from 'helpers/vuex_action_helper';
import { baseReport, headReport, comparedReportResult } from '../mock_data';

describe('Accessibility Reports actions', () => {
  let localState;
  let localStore;

  beforeEach(() => {
    localStore = createStore();
    localState = localStore.state;
  });

  describe('fetchReport', () => {
    let mock;

    beforeEach(() => {
      localState.baseEndpoint = `${TEST_HOST}/endpoint.json`;
      localState.headEndpoint = `${TEST_HOST}/endpoint.json`;
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('when no endpoints are given', () => {
      beforeEach(() => {
        localState.baseEndpoint = null;
        localState.headEndpoint = null;
      });

      it('should commit REQUEST_REPORT and RECEIVE_REPORT_ERROR mutations', done => {
        testAction(
          actions.fetchReport,
          null,
          localState,
          [
            { type: types.REQUEST_REPORT },
            {
              type: types.RECEIVE_REPORT_ERROR,
              payload: 'Accessibility report artifact not found',
            },
          ],
          [],
          done,
        );
      });
    });

    describe('success', () => {
      it('should commit REQUEST_REPORT mutation and dispatch receiveReportSuccess', done => {
        const data = { report: { summary: {} } };
        mock.onGet(`${TEST_HOST}/endpoint.json`).reply(200, data);

        testAction(
          actions.fetchReport,
          null,
          localState,
          [{ type: types.REQUEST_REPORT }],
          [
            {
              payload: [{ ...data, isHead: false }, { ...data, isHead: true }],
              type: 'receiveReportSuccess',
            },
          ],
          done,
        );
      });
    });

    describe('error', () => {
      it('should commit REQUEST_REPORT and RECEIVE_REPORT_ERROR mutations', done => {
        mock.onGet(`${TEST_HOST}/endpoint.json`).reply(500);

        testAction(
          actions.fetchReport,
          null,
          localState,
          [
            { type: types.REQUEST_REPORT },
            {
              type: types.RECEIVE_REPORT_ERROR,
              payload: 'Failed to retrieve accessibility report',
            },
          ],
          [],
          done,
        );
      });
    });
  });

  describe('receiveReportSuccess', () => {
    it('should commit RECEIVE_REPORT_SUCCESS mutation', done => {
      testAction(
        actions.receiveReportSuccess,
        [{ ...baseReport, isHead: false }, { ...headReport, isHead: true }],
        localState,
        [{ type: types.RECEIVE_REPORT_SUCCESS, payload: comparedReportResult }],
        [],
        done,
      );
    });
  });
});
