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

  const endpoint = `${TEST_HOST}/test_reports.json`;
  const defaultState = {
    endpoint,
    testReports: {},
    selectedSuite: {},
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
    state = defaultState;
  });

  afterEach(() => {
    mock.restore();
  });

  describe('fetch reports', () => {
    beforeEach(() => {
      mock.onGet(`${TEST_HOST}/test_reports.json`).replyOnce(200, testReports, {});
    });

    it('sets testReports and shows tests', done => {
      testAction(
        actions.fetchReports,
        null,
        state,
        [{ type: types.SET_REPORTS, payload: testReports }],
        [{ type: 'toggleLoading' }, { type: 'toggleLoading' }],
        done,
      );
    });

    it('should create flash on API error', done => {
      testAction(
        actions.fetchReports,
        null,
        {
          endpoint: null,
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

  describe('set selected suite', () => {
    const selectedSuite = testReports.test_suites[0];

    it('sets selectedSuite', done => {
      testAction(
        actions.setSelectedSuite,
        selectedSuite,
        state,
        [{ type: types.SET_SELECTED_SUITE, payload: selectedSuite }],
        [],
        done,
      );
    });
  });

  describe('remove selected suite', () => {
    it('sets selectedSuite to {}', done => {
      testAction(
        actions.removeSelectedSuite,
        {},
        state,
        [{ type: types.SET_SELECTED_SUITE, payload: {} }],
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
