import MockAdapter from 'axios-mock-adapter';
import { getJSONFixture } from 'helpers/fixtures';
import { TEST_HOST } from 'helpers/test_constants';
import testAction from 'helpers/vuex_action_helper';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import * as actions from '~/pipelines/stores/test_reports/actions';
import * as types from '~/pipelines/stores/test_reports/mutation_types';

jest.mock('~/flash.js');

describe('Actions TestReports Store', () => {
  let mock;
  let state;

  const testReports = getJSONFixture('pipelines/test_report.json');
  const summary = { total_count: 1 };

  const suiteEndpoint = `${TEST_HOST}/tests/suite.json`;
  const summaryEndpoint = `${TEST_HOST}/test_reports/summary.json`;
  const defaultState = {
    suiteEndpoint,
    summaryEndpoint,
    testReports: {},
    selectedSuite: null,
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
    state = { ...defaultState };
  });

  afterEach(() => {
    mock.restore();
  });

  describe('fetch report summary', () => {
    beforeEach(() => {
      mock.onGet(summaryEndpoint).replyOnce(200, summary, {});
    });

    it('sets testReports and shows tests', (done) => {
      testAction(
        actions.fetchSummary,
        null,
        state,
        [{ type: types.SET_SUMMARY, payload: summary }],
        [{ type: 'toggleLoading' }, { type: 'toggleLoading' }],
        done,
      );
    });

    it('should create flash on API error', (done) => {
      testAction(
        actions.fetchSummary,
        null,
        { summaryEndpoint: null },
        [],
        [{ type: 'toggleLoading' }, { type: 'toggleLoading' }],
        () => {
          expect(createFlash).toHaveBeenCalled();
          done();
        },
      );
    });
  });

  describe('fetch test suite', () => {
    beforeEach(() => {
      const buildIds = [1];
      testReports.test_suites[0].build_ids = buildIds;
      mock
        .onGet(suiteEndpoint, { params: { build_ids: buildIds } })
        .replyOnce(200, testReports.test_suites[0], {});
    });

    it('sets test suite and shows tests', (done) => {
      const suite = testReports.test_suites[0];
      const index = 0;

      testAction(
        actions.fetchTestSuite,
        index,
        { ...state, testReports },
        [{ type: types.SET_SUITE, payload: { suite, index } }],
        [{ type: 'toggleLoading' }, { type: 'toggleLoading' }],
        done,
      );
    });

    it('should create flash on API error', (done) => {
      const index = 0;

      testAction(
        actions.fetchTestSuite,
        index,
        { ...state, testReports, suiteEndpoint: null },
        [],
        [{ type: 'toggleLoading' }, { type: 'toggleLoading' }],
        () => {
          expect(createFlash).toHaveBeenCalled();
          done();
        },
      );
    });

    describe('when we already have the suite data', () => {
      it('should not fetch suite', (done) => {
        const index = 0;
        testReports.test_suites[0].hasFullSuite = true;

        testAction(actions.fetchTestSuite, index, { ...state, testReports }, [], [], done);
      });
    });
  });

  describe('set selected suite index', () => {
    it('sets selectedSuiteIndex', (done) => {
      const selectedSuiteIndex = 0;

      testAction(
        actions.setSelectedSuiteIndex,
        selectedSuiteIndex,
        { ...state, hasFullReport: true },
        [{ type: types.SET_SELECTED_SUITE_INDEX, payload: selectedSuiteIndex }],
        [],
        done,
      );
    });
  });

  describe('remove selected suite index', () => {
    it('sets selectedSuiteIndex to null', (done) => {
      testAction(
        actions.removeSelectedSuiteIndex,
        {},
        state,
        [{ type: types.SET_SELECTED_SUITE_INDEX, payload: null }],
        [],
        done,
      );
    });
  });

  describe('toggles loading', () => {
    it('sets isLoading to true', (done) => {
      testAction(actions.toggleLoading, {}, state, [{ type: types.TOGGLE_LOADING }], [], done);
    });

    it('toggles isLoading to false', (done) => {
      testAction(
        actions.toggleLoading,
        {},
        { ...state, isLoading: true },
        [{ type: types.TOGGLE_LOADING }],
        [],
        done,
      );
    });
  });
});
