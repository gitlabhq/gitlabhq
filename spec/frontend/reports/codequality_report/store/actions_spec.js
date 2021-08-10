import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import { TEST_HOST } from 'spec/test_constants';
import axios from '~/lib/utils/axios_utils';
import createStore from '~/reports/codequality_report/store';
import * as actions from '~/reports/codequality_report/store/actions';
import * as types from '~/reports/codequality_report/store/mutation_types';
import { STATUS_NOT_FOUND } from '~/reports/constants';
import { reportIssues, parsedReportIssues } from '../mock_data';

const pollInterval = 123;
const pollIntervalHeader = {
  'Poll-Interval': pollInterval,
};

describe('Codequality Reports actions', () => {
  let localState;
  let localStore;

  beforeEach(() => {
    localStore = createStore();
    localState = localStore.state;
  });

  describe('setPaths', () => {
    it('should commit SET_PATHS mutation', (done) => {
      const paths = {
        baseBlobPath: 'baseBlobPath',
        headBlobPath: 'headBlobPath',
        reportsPath: 'reportsPath',
        helpPath: 'codequalityHelpPath',
      };

      testAction(
        actions.setPaths,
        paths,
        localState,
        [{ type: types.SET_PATHS, payload: paths }],
        [],
        done,
      );
    });
  });

  describe('fetchReports', () => {
    const endpoint = `${TEST_HOST}/codequality_reports.json`;
    let mock;

    beforeEach(() => {
      localState.reportsPath = endpoint;
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('on success', () => {
      it('commits REQUEST_REPORTS and dispatches receiveReportsSuccess', (done) => {
        mock.onGet(endpoint).reply(200, reportIssues);

        testAction(
          actions.fetchReports,
          null,
          localState,
          [{ type: types.REQUEST_REPORTS }],
          [
            {
              payload: parsedReportIssues,
              type: 'receiveReportsSuccess',
            },
          ],
          done,
        );
      });
    });

    describe('on error', () => {
      it('commits REQUEST_REPORTS and dispatches receiveReportsError', (done) => {
        mock.onGet(endpoint).reply(500);

        testAction(
          actions.fetchReports,
          null,
          localState,
          [{ type: types.REQUEST_REPORTS }],
          [{ type: 'receiveReportsError', payload: expect.any(Error) }],
          done,
        );
      });
    });

    describe('when base report is not found', () => {
      it('commits REQUEST_REPORTS and dispatches receiveReportsError', (done) => {
        const data = { status: STATUS_NOT_FOUND };
        mock.onGet(`${TEST_HOST}/codequality_reports.json`).reply(200, data);

        testAction(
          actions.fetchReports,
          null,
          localState,
          [{ type: types.REQUEST_REPORTS }],
          [{ type: 'receiveReportsError', payload: data }],
          done,
        );
      });
    });

    describe('while waiting for report results', () => {
      it('continues polling until it receives data', (done) => {
        mock
          .onGet(endpoint)
          .replyOnce(204, undefined, pollIntervalHeader)
          .onGet(endpoint)
          .reply(200, reportIssues);

        Promise.all([
          testAction(
            actions.fetchReports,
            null,
            localState,
            [{ type: types.REQUEST_REPORTS }],
            [
              {
                payload: parsedReportIssues,
                type: 'receiveReportsSuccess',
              },
            ],
            done,
          ),
          axios
            // wait for initial NO_CONTENT response to be fulfilled
            .waitForAll()
            .then(() => {
              jest.advanceTimersByTime(pollInterval);
            }),
        ]).catch(done.fail);
      });

      it('continues polling until it receives an error', (done) => {
        mock
          .onGet(endpoint)
          .replyOnce(204, undefined, pollIntervalHeader)
          .onGet(endpoint)
          .reply(500);

        Promise.all([
          testAction(
            actions.fetchReports,
            null,
            localState,
            [{ type: types.REQUEST_REPORTS }],
            [{ type: 'receiveReportsError', payload: expect.any(Error) }],
            done,
          ),
          axios
            // wait for initial NO_CONTENT response to be fulfilled
            .waitForAll()
            .then(() => {
              jest.advanceTimersByTime(pollInterval);
            }),
        ]).catch(done.fail);
      });
    });
  });

  describe('receiveReportsSuccess', () => {
    it('commits RECEIVE_REPORTS_SUCCESS', (done) => {
      const data = { issues: [] };

      testAction(
        actions.receiveReportsSuccess,
        data,
        localState,
        [{ type: types.RECEIVE_REPORTS_SUCCESS, payload: data }],
        [],
        done,
      );
    });
  });

  describe('receiveReportsError', () => {
    it('commits RECEIVE_REPORTS_ERROR', (done) => {
      testAction(
        actions.receiveReportsError,
        null,
        localState,
        [{ type: types.RECEIVE_REPORTS_ERROR, payload: null }],
        [],
        done,
      );
    });
  });
});
