import MockAdapter from 'axios-mock-adapter';
import testReports from 'test_fixtures/pipelines/test_report.json';
import { TEST_HOST } from 'helpers/test_constants';
import testAction from 'helpers/vuex_action_helper';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import * as actions from '~/ci/pipeline_details/stores/test_reports/actions';
import * as types from '~/ci/pipeline_details/stores/test_reports/mutation_types';

jest.mock('~/alert');

describe('Actions TestReports Store', () => {
  let mock;
  let state;

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
      mock.onGet(summaryEndpoint).replyOnce(HTTP_STATUS_OK, summary, {});
    });

    it('sets testReports and shows tests', () => {
      return testAction(
        actions.fetchSummary,
        null,
        state,
        [{ type: types.SET_SUMMARY, payload: summary }],
        [{ type: 'toggleLoading' }, { type: 'toggleLoading' }],
      );
    });

    it('should create alert on API error', async () => {
      await testAction(
        actions.fetchSummary,
        null,
        { summaryEndpoint: null },
        [],
        [{ type: 'toggleLoading' }, { type: 'toggleLoading' }],
      );
      expect(createAlert).toHaveBeenCalled();
    });
  });

  describe('fetch test suite', () => {
    beforeEach(() => {
      const buildIds = [1];
      testReports.test_suites[0].build_ids = buildIds;
      mock
        .onGet(suiteEndpoint, { params: { build_ids: buildIds } })
        .replyOnce(HTTP_STATUS_OK, testReports.test_suites[0], {});
    });

    it('sets test suite and shows tests', () => {
      const suite = testReports.test_suites[0];
      const index = 0;

      return testAction(
        actions.fetchTestSuite,
        index,
        { ...state, testReports },
        [{ type: types.SET_SUITE, payload: { suite, index } }],
        [{ type: 'toggleLoading' }, { type: 'toggleLoading' }],
      );
    });

    it('should call SET_SUITE_ERROR on error', () => {
      const index = 0;

      return testAction(
        actions.fetchTestSuite,
        index,
        { ...state, testReports, suiteEndpoint: null },
        [{ type: types.SET_SUITE_ERROR, payload: expect.any(Error) }],
        [{ type: 'toggleLoading' }, { type: 'toggleLoading' }],
      );
    });

    describe('when we already have the suite data', () => {
      it('should not fetch suite', () => {
        const index = 0;
        testReports.test_suites[0].hasFullSuite = true;

        return testAction(actions.fetchTestSuite, index, { ...state, testReports }, [], []);
      });
    });
  });

  describe('set selected suite index', () => {
    it('sets selectedSuiteIndex', () => {
      const selectedSuiteIndex = 0;

      return testAction(
        actions.setSelectedSuiteIndex,
        selectedSuiteIndex,
        { ...state, hasFullReport: true },
        [{ type: types.SET_SELECTED_SUITE_INDEX, payload: selectedSuiteIndex }],
        [],
      );
    });
  });

  describe('remove selected suite index', () => {
    it('sets selectedSuiteIndex to null', () => {
      return testAction(
        actions.removeSelectedSuiteIndex,
        {},
        state,
        [{ type: types.SET_SELECTED_SUITE_INDEX, payload: null }],
        [],
      );
    });
  });

  describe('toggles loading', () => {
    it('sets isLoading to true', () => {
      return testAction(actions.toggleLoading, {}, state, [{ type: types.TOGGLE_LOADING }], []);
    });

    it('toggles isLoading to false', () => {
      return testAction(
        actions.toggleLoading,
        {},
        { ...state, isLoading: true },
        [{ type: types.TOGGLE_LOADING }],
        [],
      );
    });
  });
});
