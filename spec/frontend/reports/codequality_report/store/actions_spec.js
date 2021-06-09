import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import { TEST_HOST } from 'spec/test_constants';
import axios from '~/lib/utils/axios_utils';
import createStore from '~/reports/codequality_report/store';
import * as actions from '~/reports/codequality_report/store/actions';
import * as types from '~/reports/codequality_report/store/mutation_types';
import { reportIssues, parsedReportIssues } from '../mock_data';

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
        basePath: 'basePath',
        headPath: 'headPath',
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
    let mock;

    beforeEach(() => {
      localState.reportsPath = `${TEST_HOST}/codequality_reports.json`;
      localState.basePath = '/base/path';
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('on success', () => {
      it('commits REQUEST_REPORTS and dispatches receiveReportsSuccess', (done) => {
        mock.onGet(`${TEST_HOST}/codequality_reports.json`).reply(200, reportIssues);

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
        mock.onGet(`${TEST_HOST}/codequality_reports.json`).reply(500);

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

    describe('with no base path', () => {
      it('commits REQUEST_REPORTS and dispatches receiveReportsError', (done) => {
        localState.basePath = null;

        testAction(
          actions.fetchReports,
          null,
          localState,
          [{ type: types.REQUEST_REPORTS }],
          [{ type: 'receiveReportsError' }],
          done,
        );
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
