import MockAdapter from 'axios-mock-adapter';
import { getJSONFixture } from 'helpers/fixtures';
import axios from '~/lib/utils/axios_utils';
import * as actions from '~/pipelines/stores/test_reports/actions';
import * as types from '~/pipelines/stores/test_reports/mutation_types';
import { TEST_HOST } from '../../../helpers/test_constants';
import testAction from '../../../helpers/vuex_action_helper';
import createFlash from '~/flash';

jest.mock('~/flash.js');

describe('Actions TestReports Store', () => {
  let mock;
  let state;

  const testReports = getJSONFixture('pipelines/test_report.json');
  const summary = { total_count: 1 };

  const fullReportEndpoint = `${TEST_HOST}/test_reports.json`;
  const summaryEndpoint = `${TEST_HOST}/test_reports/summary.json`;
  const defaultState = {
    fullReportEndpoint,
    summaryEndpoint,
    testReports: {},
    selectedSuite: null,
    summary: {},
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
    state = defaultState;
  });

  afterEach(() => {
    mock.restore();
  });

  describe('fetch report summary', () => {
    beforeEach(() => {
      mock.onGet(summaryEndpoint).replyOnce(200, summary, {});
    });

    it('sets testReports and shows tests', done => {
      testAction(
        actions.fetchSummary,
        null,
        state,
        [{ type: types.SET_SUMMARY, payload: summary }],
        [],
        done,
      );
    });

    it('should create flash on API error', done => {
      testAction(
        actions.fetchSummary,
        null,
        {
          summaryEndpoint: null,
        },
        [],
        [],
        () => {
          expect(createFlash).toHaveBeenCalled();
          done();
        },
      );
    });
  });

  describe('fetch full report', () => {
    beforeEach(() => {
      mock.onGet(fullReportEndpoint).replyOnce(200, testReports, {});
    });

    it('sets testReports and shows tests', done => {
      testAction(
        actions.fetchFullReport,
        null,
        state,
        [{ type: types.SET_REPORTS, payload: testReports }],
        [{ type: 'toggleLoading' }, { type: 'toggleLoading' }],
        done,
      );
    });

    it('should create flash on API error', done => {
      testAction(
        actions.fetchFullReport,
        null,
        {
          fullReportEndpoint: null,
        },
        [],
        [{ type: 'toggleLoading' }, { type: 'toggleLoading' }],
        () => {
          expect(createFlash).toHaveBeenCalled();
          done();
        },
      );
    });
  });

  describe('set selected suite index', () => {
    const selectedSuiteIndex = 0;

    it('sets selectedSuiteIndex', done => {
      testAction(
        actions.setSelectedSuiteIndex,
        selectedSuiteIndex,
        state,
        [{ type: types.SET_SELECTED_SUITE_INDEX, payload: selectedSuiteIndex }],
        [],
        done,
      );
    });
  });

  describe('remove selected suite index', () => {
    it('sets selectedSuiteIndex to null', done => {
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
    it('sets isLoading to true', done => {
      testAction(actions.toggleLoading, {}, state, [{ type: types.TOGGLE_LOADING }], [], done);
    });

    it('toggles isLoading to false', done => {
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
