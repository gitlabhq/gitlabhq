import MockAdapter from 'axios-mock-adapter';

import testAction from 'helpers/vuex_action_helper';
import * as types from '~/logs/stores/mutation_types';
import { convertToFixedRange } from '~/lib/utils/datetime_range';
import logsPageState from '~/logs/stores/state';
import {
  setInitData,
  setSearch,
  showPodLogs,
  fetchEnvironments,
  fetchLogs,
  fetchMoreLogsPrepend,
} from '~/logs/stores/actions';

import { defaultTimeRange } from '~/vue_shared/constants';

import axios from '~/lib/utils/axios_utils';
import flash from '~/flash';

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

jest.mock('~/flash');
jest.mock('~/lib/utils/datetime_range');
jest.mock('~/logs/utils');

const mockDefaultRange = {
  start: '2020-01-10T18:00:00.000Z',
  end: '2020-01-10T10:00:00.000Z',
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

  convertToFixedRange.mockImplementation(range => {
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

  afterEach(() => {
    flash.mockClear();
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

  describe('setSearch', () => {
    it('should commit search mutation', () =>
      testAction(
        setSearch,
        mockSearch,
        state,
        [{ type: types.SET_SEARCH, payload: mockSearch }],
        [{ type: 'fetchLogs' }],
      ));
  });

  describe('showPodLogs', () => {
    it('should commit pod name', () =>
      testAction(
        showPodLogs,
        mockPodName,
        state,
        [{ type: types.SET_CURRENT_POD_NAME, payload: mockPodName }],
        [{ type: 'fetchLogs' }],
      ));
  });

  describe('fetchEnvironments', () => {
    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    it('should commit RECEIVE_ENVIRONMENTS_DATA_SUCCESS mutation on correct data', () => {
      mock.onGet(mockEnvironmentsEndpoint).replyOnce(200, { environments: mockEnvironments });
      return testAction(
        fetchEnvironments,
        mockEnvironmentsEndpoint,
        state,
        [
          { type: types.REQUEST_ENVIRONMENTS_DATA },
          { type: types.RECEIVE_ENVIRONMENTS_DATA_SUCCESS, payload: mockEnvironments },
        ],
        [{ type: 'fetchLogs' }],
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
        () => {
          expect(flash).toHaveBeenCalledTimes(1);
        },
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
          { type: types.REQUEST_PODS_DATA },
          { type: types.REQUEST_LOGS_DATA },
          { type: types.SET_CURRENT_POD_NAME, payload: mockPodName },
          { type: types.RECEIVE_PODS_DATA_SUCCESS, payload: mockPods },
          {
            type: types.RECEIVE_LOGS_DATA_SUCCESS,
            payload: { logs: mockLogsResult, cursor: mockNextCursor },
          },
        ];

        expectedActions = [];
      });

      it('should commit logs and pod data when there is pod name defined', () => {
        state.pods.current = mockPodName;

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
            start: mockFixedRange.start,
            end: mockFixedRange.end,
            cursor: mockCursor,
          });
        });
      });

      it('should commit logs and pod data when there is pod name and search and a faulty date range', () => {
        state.pods.current = mockPodName;
        state.search = mockSearch;
        state.timeRange.current = 'INVALID_TIME_RANGE';

        return testAction(fetchLogs, null, state, expectedMutations, expectedActions, () => {
          expect(latestGetParams()).toEqual({
            pod_name: mockPodName,
            search: mockSearch,
          });
          // Warning about time ranges was issued
          expect(flash).toHaveBeenCalledTimes(1);
          expect(flash).toHaveBeenCalledWith(expect.any(String), 'warning');
        });
      });

      it('should commit logs and pod data when no pod name defined', () => {
        state.timeRange.current = mockDefaultRange;

        return testAction(fetchLogs, null, state, expectedMutations, expectedActions, () => {
          expect(latestGetParams()).toEqual({});
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
              start: mockFixedRange.start,
              end: mockFixedRange.end,
              cursor: mockCursor,
            });
          },
        );
      });

      it('should commit logs and pod data when there is pod name and search and a faulty date range', () => {
        state.pods.current = mockPodName;
        state.search = mockSearch;
        state.timeRange.current = 'INVALID_TIME_RANGE';

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
            // Warning about time ranges was issued
            expect(flash).toHaveBeenCalledTimes(1);
            expect(flash).toHaveBeenCalledWith(expect.any(String), 'warning');
          },
        );
      });

      it('should commit logs and pod data when no pod name defined', () => {
        state.timeRange.current = mockDefaultRange;

        return testAction(
          fetchMoreLogsPrepend,
          null,
          state,
          expectedMutations,
          expectedActions,
          () => {
            expect(latestGetParams()).toEqual({});
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

      return testAction(
        fetchLogs,
        null,
        state,
        [
          { type: types.REQUEST_PODS_DATA },
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
