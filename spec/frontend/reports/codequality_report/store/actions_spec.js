import MockAdapter from 'axios-mock-adapter';
import { TEST_HOST } from 'spec/test_constants';
import testAction from 'helpers/vuex_action_helper';
import axios from '~/lib/utils/axios_utils';
import * as actions from '~/reports/codequality_report/store/actions';
import * as types from '~/reports/codequality_report/store/mutation_types';
import createStore from '~/reports/codequality_report/store';
import { headIssues, baseIssues, mockParsedHeadIssues, mockParsedBaseIssues } from '../mock_data';

// mock codequality comparison worker
jest.mock('~/reports/codequality_report/workers/codequality_comparison_worker', () =>
  jest.fn().mockImplementation(() => {
    return {
      addEventListener: (eventName, callback) => {
        callback({
          data: {
            newIssues: [mockParsedHeadIssues[0]],
            resolvedIssues: [mockParsedBaseIssues[0]],
          },
        });
      },
    };
  }),
);

describe('Codequality Reports actions', () => {
  let localState;
  let localStore;

  beforeEach(() => {
    localStore = createStore();
    localState = localStore.state;
  });

  describe('setPaths', () => {
    it('should commit SET_PATHS mutation', done => {
      const paths = {
        basePath: 'basePath',
        headPath: 'headPath',
        baseBlobPath: 'baseBlobPath',
        headBlobPath: 'headBlobPath',
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
      localState.headPath = `${TEST_HOST}/head.json`;
      localState.basePath = `${TEST_HOST}/base.json`;
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('on success', () => {
      it('commits REQUEST_REPORTS and dispatches receiveReportsSuccess', done => {
        mock.onGet(`${TEST_HOST}/head.json`).reply(200, headIssues);
        mock.onGet(`${TEST_HOST}/base.json`).reply(200, baseIssues);

        testAction(
          actions.fetchReports,
          null,
          localState,
          [{ type: types.REQUEST_REPORTS }],
          [
            {
              payload: {
                newIssues: [mockParsedHeadIssues[0]],
                resolvedIssues: [mockParsedBaseIssues[0]],
              },
              type: 'receiveReportsSuccess',
            },
          ],
          done,
        );
      });
    });

    describe('on error', () => {
      it('commits REQUEST_REPORTS and dispatches receiveReportsError', done => {
        mock.onGet(`${TEST_HOST}/head.json`).reply(500);

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

    describe('with no base path', () => {
      it('commits REQUEST_REPORTS and dispatches receiveReportsError', done => {
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
    it('commits RECEIVE_REPORTS_SUCCESS', done => {
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
    it('commits RECEIVE_REPORTS_ERROR', done => {
      testAction(
        actions.receiveReportsError,
        null,
        localState,
        [{ type: types.RECEIVE_REPORTS_ERROR }],
        [],
        done,
      );
    });
  });
});
