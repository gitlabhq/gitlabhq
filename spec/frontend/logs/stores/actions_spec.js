import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import axios from '~/lib/utils/axios_utils';
import { convertToFixedRange } from '~/lib/utils/datetime_range';
import { TOKEN_TYPE_POD_NAME } from '~/logs/constants';
import {
  setInitData,
  showFilteredLogs,
  showPodLogs,
  fetchEnvironments,
  fetchLogs,
  fetchMoreLogsPrepend,
} from '~/logs/stores/actions';
import * as types from '~/logs/stores/mutation_types';
import logsPageState from '~/logs/stores/state';
import Tracking from '~/tracking';

import { defaultTimeRange } from '~/vue_shared/constants';

import {
  mockPodName,
  mockEnvironmentsEndpoint,
  mockEnvironments,
  mockPods,
  mockLogsResult,
  mockEnvName,
  mockSearch,
  mockLogsEndpoint,
  mockResponse,
  mockCursor,
  mockNextCursor,
} from '../mock_data';

jest.mock('~/lib/utils/datetime_range');
jest.mock('~/logs/utils');

const mockDefaultRange = {
  start: '2020-01-10T18:00:00.000Z',
  end: '2020-01-10T19:00:00.000Z',
};
const mockFixedRange = {
  start: '2020-01-09T18:06:20.000Z',
  end: '2020-01-09T18:36:20.000Z',
};
const mockRollingRange = {
  duration: 120,
};
const mockRollingRangeAsFixed = {
  start: '2020-01-10T18:00:00.000Z',
  end: '2020-01-10T17:58:00.000Z',
};

describe('Logs Store actions', () => {
  let state;
  let mock;

  const latestGetParams = () => mock.history.get[mock.history.get.length - 1].params;

  convertToFixedRange.mockImplementation((range) => {
    if (range === defaultTimeRange) {
      return { ...mockDefaultRange };
    }
    if (range === mockFixedRange) {
      return { ...mockFixedRange };
    }
    if (range === mockRollingRange) {
      return { ...mockRollingRangeAsFixed };
    }
    throw new Error('Invalid time range');
  });

  beforeEach(() => {
    state = logsPageState();
  });

  describe('setInitData', () => {
    it('should commit environment and pod name mutation', () =>
      testAction(
        setInitData,
        { timeRange: mockFixedRange, environmentName: mockEnvName, podName: mockPodName },
        state,
        [
          { type: types.SET_TIME_RANGE, payload: mockFixedRange },
          { type: types.SET_PROJECT_ENVIRONMENT, payload: mockEnvName },
          { type: types.SET_CURRENT_POD_NAME, payload: mockPodName },
        ],
      ));
  });

  describe('showFilteredLogs', () => {
    it('empty search should filter with defaults', () =>
      testAction(
        showFilteredLogs,
        undefined,
        state,
        [
          { type: types.SET_CURRENT_POD_NAME, payload: null },
          { type: types.SET_SEARCH, payload: '' },
        ],
        [{ type: 'fetchLogs', payload: 'used_search_bar' }],
      ));

    it('text search should filter with a search term', () =>
      testAction(
        showFilteredLogs,
        [mockSearch],
        state,
        [
          { type: types.SET_CURRENT_POD_NAME, payload: null },
          { type: types.SET_SEARCH, payload: mockSearch },
        ],
        [{ type: 'fetchLogs', payload: 'used_search_bar' }],
      ));

    it('pod search should filter with a search term', () =>
      testAction(
        showFilteredLogs,
        [{ type: TOKEN_TYPE_POD_NAME, value: { data: mockPodName, operator: '=' } }],
        state,
        [
          { type: types.SET_CURRENT_POD_NAME, payload: mockPodName },
          { type: types.SET_SEARCH, payload: '' },
        ],
        [{ type: 'fetchLogs', payload: 'used_search_bar' }],
      ));

    it('pod search should filter with a pod selection and a search term', () =>
      testAction(
        showFilteredLogs,
        [{ type: TOKEN_TYPE_POD_NAME, value: { data: mockPodName, operator: '=' } }, mockSearch],
        state,
        [
          { type: types.SET_CURRENT_POD_NAME, payload: mockPodName },
          { type: types.SET_SEARCH, payload: mockSearch },
        ],
        [{ type: 'fetchLogs', payload: 'used_search_bar' }],
      ));

    it('pod search should filter with a pod selection and two search terms', () =>
      testAction(
        showFilteredLogs,
        ['term1', 'term2'],
        state,
        [
          { type: types.SET_CURRENT_POD_NAME, payload: null },
          { type: types.SET_SEARCH, payload: `term1 term2` },
        ],
        [{ type: 'fetchLogs', payload: 'used_search_bar' }],
      ));

    it('pod search should filter with a pod selection and a search terms before and after', () =>
      testAction(
        showFilteredLogs,
        [
          'term1',
          { type: TOKEN_TYPE_POD_NAME, value: { data: mockPodName, operator: '=' } },
          'term2',
        ],
        state,
        [
          { type: types.SET_CURRENT_POD_NAME, payload: mockPodName },
          { type: types.SET_SEARCH, payload: `term1 term2` },
        ],
        [{ type: 'fetchLogs', payload: 'used_search_bar' }],
      ));
  });

  describe('showPodLogs', () => {
    it('should commit pod name', () =>
      testAction(
        showPodLogs,
        mockPodName,
        state,
        [{ type: types.SET_CURRENT_POD_NAME, payload: mockPodName }],
        [{ type: 'fetchLogs', payload: 'pod_log_changed' }],
      ));
  });

  describe('fetchEnvironments', () => {
    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    it('should commit RECEIVE_ENVIRONMENTS_DATA_SUCCESS mutation on correct data', () => {
      mock.onGet(mockEnvironmentsEndpoint).replyOnce(200, mockEnvironments);
      return testAction(
        fetchEnvironments,
        mockEnvironmentsEndpoint,
        state,
        [
          { type: types.REQUEST_ENVIRONMENTS_DATA },
          { type: types.RECEIVE_ENVIRONMENTS_DATA_SUCCESS, payload: mockEnvironments },
        ],
        [{ type: 'fetchLogs', payload: 'environment_selected' }],
      );
    });

    it('should commit RECEIVE_ENVIRONMENTS_DATA_ERROR on wrong data', () => {
      mock.onGet(mockEnvironmentsEndpoint).replyOnce(500);
      return testAction(
        fetchEnvironments,
        mockEnvironmentsEndpoint,
        state,
        [
          { type: types.REQUEST_ENVIRONMENTS_DATA },
          { type: types.RECEIVE_ENVIRONMENTS_DATA_ERROR },
        ],
        [],
      );
    });
  });

  describe('when the backend responds succesfully', () => {
    let expectedMutations;
    let expectedActions;

    beforeEach(() => {
      mock = new MockAdapter(axios);
      mock.onGet(mockLogsEndpoint).reply(200, mockResponse);
      mock.onGet(mockLogsEndpoint).replyOnce(202); // mock reactive cache

      state.environments.options = mockEnvironments;
      state.environments.current = mockEnvName;
    });

    afterEach(() => {
      mock.reset();
    });

    describe('fetchLogs', () => {
      beforeEach(() => {
        expectedMutations = [
          { type: types.REQUEST_LOGS_DATA },
          {
            type: types.RECEIVE_LOGS_DATA_SUCCESS,
            payload: { logs: mockLogsResult, cursor: mockNextCursor },
          },
          { type: types.SET_CURRENT_POD_NAME, payload: mockPodName },
          { type: types.RECEIVE_PODS_DATA_SUCCESS, payload: mockPods },
        ];

        expectedActions = [];
      });

      it('should commit logs and pod data when there is pod name defined', () => {
        state.pods.current = mockPodName;
        state.timeRange.current = mockFixedRange;

        return testAction(fetchLogs, null, state, expectedMutations, expectedActions, () => {
          expect(latestGetParams()).toMatchObject({
            pod_name: mockPodName,
          });
        });
      });

      it('should commit logs and pod data when there is pod name defined and a non-default date range', () => {
        state.pods.current = mockPodName;
        state.timeRange.current = mockFixedRange;
        state.logs.cursor = mockCursor;

        return testAction(fetchLogs, null, state, expectedMutations, expectedActions, () => {
          expect(latestGetParams()).toEqual({
            pod_name: mockPodName,
            start_time: mockFixedRange.start,
            end_time: mockFixedRange.end,
            cursor: mockCursor,
          });
        });
      });

      it('should commit logs and pod data when there is pod name and search and a faulty date range', () => {
        state.pods.current = mockPodName;
        state.search = mockSearch;
        state.timeRange.current = 'INVALID_TIME_RANGE';

        expectedMutations.splice(1, 0, {
          type: types.SHOW_TIME_RANGE_INVALID_WARNING,
        });

        return testAction(fetchLogs, null, state, expectedMutations, expectedActions, () => {
          expect(latestGetParams()).toEqual({
            pod_name: mockPodName,
            search: mockSearch,
          });
        });
      });

      it('should commit logs and pod data when no pod name defined', () => {
        state.timeRange.current = defaultTimeRange;

        return testAction(fetchLogs, null, state, expectedMutations, expectedActions, () => {
          expect(latestGetParams()).toEqual({
            start_time: expect.any(String),
            end_time: expect.any(String),
          });
        });
      });
    });

    describe('fetchMoreLogsPrepend', () => {
      beforeEach(() => {
        expectedMutations = [
          { type: types.REQUEST_LOGS_DATA_PREPEND },
          {
            type: types.RECEIVE_LOGS_DATA_PREPEND_SUCCESS,
            payload: { logs: mockLogsResult, cursor: mockNextCursor },
          },
        ];

        expectedActions = [];
      });

      it('should commit logs and pod data when there is pod name defined', () => {
        state.pods.current = mockPodName;
        state.timeRange.current = mockFixedRange;

        expectedActions = [];

        return testAction(
          fetchMoreLogsPrepend,
          null,
          state,
          expectedMutations,
          expectedActions,
          () => {
            expect(latestGetParams()).toMatchObject({
              pod_name: mockPodName,
            });
          },
        );
      });

      it('should commit logs and pod data when there is pod name defined and a non-default date range', () => {
        state.pods.current = mockPodName;
        state.timeRange.current = mockFixedRange;
        state.logs.cursor = mockCursor;

        return testAction(
          fetchMoreLogsPrepend,
          null,
          state,
          expectedMutations,
          expectedActions,
          () => {
            expect(latestGetParams()).toEqual({
              pod_name: mockPodName,
              start_time: mockFixedRange.start,
              end_time: mockFixedRange.end,
              cursor: mockCursor,
            });
          },
        );
      });

      it('should commit logs and pod data when there is pod name and search and a faulty date range', () => {
        state.pods.current = mockPodName;
        state.search = mockSearch;
        state.timeRange.current = 'INVALID_TIME_RANGE';

        expectedMutations.splice(1, 0, {
          type: types.SHOW_TIME_RANGE_INVALID_WARNING,
        });

        return testAction(
          fetchMoreLogsPrepend,
          null,
          state,
          expectedMutations,
          expectedActions,
          () => {
            expect(latestGetParams()).toEqual({
              pod_name: mockPodName,
              search: mockSearch,
            });
          },
        );
      });

      it('should commit logs and pod data when no pod name defined', () => {
        state.timeRange.current = defaultTimeRange;

        return testAction(
          fetchMoreLogsPrepend,
          null,
          state,
          expectedMutations,
          expectedActions,
          () => {
            expect(latestGetParams()).toEqual({
              start_time: expect.any(String),
              end_time: expect.any(String),
            });
          },
        );
      });

      it('should not commit logs or pod data when it has reached the end', () => {
        state.logs.isComplete = true;
        state.logs.cursor = null;

        return testAction(
          fetchMoreLogsPrepend,
          null,
          state,
          [], // no mutations done
          [], // no actions dispatched
          () => {
            expect(mock.history.get).toHaveLength(0);
          },
        );
      });
    });
  });

  describe('when the backend responds with an error', () => {
    beforeEach(() => {
      mock = new MockAdapter(axios);
      mock.onGet(mockLogsEndpoint).reply(500);
    });

    afterEach(() => {
      mock.reset();
    });

    it('fetchLogs should commit logs and pod errors', () => {
      state.environments.options = mockEnvironments;
      state.environments.current = mockEnvName;
      state.timeRange.current = defaultTimeRange;

      return testAction(
        fetchLogs,
        null,
        state,
        [
          { type: types.REQUEST_LOGS_DATA },
          { type: types.RECEIVE_PODS_DATA_ERROR },
          { type: types.RECEIVE_LOGS_DATA_ERROR },
        ],
        [],
        () => {
          expect(mock.history.get[0].url).toBe(mockLogsEndpoint);
        },
      );
    });

    it('fetchMoreLogsPrepend should commit logs and pod errors', () => {
      state.environments.options = mockEnvironments;
      state.environments.current = mockEnvName;
      state.timeRange.current = defaultTimeRange;

      return testAction(
        fetchMoreLogsPrepend,
        null,
        state,
        [
          { type: types.REQUEST_LOGS_DATA_PREPEND },
          { type: types.RECEIVE_LOGS_DATA_PREPEND_ERROR },
        ],
        [],
        () => {
          expect(mock.history.get[0].url).toBe(mockLogsEndpoint);
        },
      );
    });
  });
});

describe('Tracking user interaction', () => {
  let commit;
  let dispatch;
  let state;
  let mock;

  beforeEach(() => {
    jest.spyOn(Tracking, 'event');
    commit = jest.fn();
    dispatch = jest.fn();
    state = logsPageState();
    state.environments.options = mockEnvironments;
    state.environments.current = mockEnvName;

    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.reset();
  });

  describe('Logs with data', () => {
    beforeEach(() => {
      mock.onGet(mockLogsEndpoint).reply(200, mockResponse);
      mock.onGet(mockLogsEndpoint).replyOnce(202); // mock reactive cache
    });

    it('tracks fetched logs with data', () => {
      return fetchLogs({ state, commit, dispatch }, 'environment_selected').then(() => {
        expect(Tracking.event).toHaveBeenCalledWith(document.body.dataset.page, 'logs_view', {
          label: 'environment_selected',
          property: 'count',
          value: 1,
        });
      });
    });
  });

  describe('Logs without data', () => {
    beforeEach(() => {
      mock.onGet(mockLogsEndpoint).reply(200, {
        ...mockResponse,
        logs: [],
      });
      mock.onGet(mockLogsEndpoint).replyOnce(202); // mock reactive cache
    });

    it('does not track empty log responses', () => {
      return fetchLogs({ state, commit, dispatch }).then(() => {
        expect(Tracking.event).not.toHaveBeenCalled();
      });
    });
  });
});
