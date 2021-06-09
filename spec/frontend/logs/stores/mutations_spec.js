import * as types from '~/logs/stores/mutation_types';
import mutations from '~/logs/stores/mutations';

import logsPageState from '~/logs/stores/state';
import {
  mockEnvName,
  mockEnvironments,
  mockPods,
  mockPodName,
  mockLogsResult,
  mockSearch,
  mockCursor,
  mockNextCursor,
} from '../mock_data';

describe('Logs Store Mutations', () => {
  let state;

  beforeEach(() => {
    state = logsPageState();
  });

  it('ensures mutation types are correctly named', () => {
    Object.keys(types).forEach((k) => {
      expect(k).toEqual(types[k]);
    });
  });

  describe('SET_PROJECT_ENVIRONMENT', () => {
    it('sets the environment', () => {
      mutations[types.SET_PROJECT_ENVIRONMENT](state, mockEnvName);
      expect(state.environments.current).toEqual(mockEnvName);
    });
  });

  describe('SET_SEARCH', () => {
    it('sets the search', () => {
      mutations[types.SET_SEARCH](state, mockSearch);
      expect(state.search).toEqual(mockSearch);
    });
  });

  describe('REQUEST_ENVIRONMENTS_DATA', () => {
    it('inits data', () => {
      mutations[types.REQUEST_ENVIRONMENTS_DATA](state);
      expect(state.environments.options).toEqual([]);
      expect(state.environments.isLoading).toEqual(true);
    });
  });

  describe('RECEIVE_ENVIRONMENTS_DATA_SUCCESS', () => {
    it('receives environments data and stores it as options', () => {
      expect(state.environments.options).toEqual([]);

      mutations[types.RECEIVE_ENVIRONMENTS_DATA_SUCCESS](state, mockEnvironments);

      expect(state.environments.options).toEqual(mockEnvironments);
      expect(state.environments.isLoading).toEqual(false);
    });
  });

  describe('RECEIVE_ENVIRONMENTS_DATA_ERROR', () => {
    it('captures an error loading environments', () => {
      mutations[types.RECEIVE_ENVIRONMENTS_DATA_ERROR](state);

      expect(state.environments).toEqual({
        options: [],
        isLoading: false,
        current: null,
        fetchError: true,
      });
    });
  });

  describe('REQUEST_LOGS_DATA', () => {
    it('starts loading for logs', () => {
      mutations[types.REQUEST_LOGS_DATA](state);

      expect(state.timeRange.current).toEqual({
        start: expect.any(String),
        end: expect.any(String),
      });

      expect(state.logs).toEqual({
        lines: [],
        cursor: null,
        fetchError: false,
        isLoading: true,
        isComplete: false,
      });
    });
  });

  describe('RECEIVE_LOGS_DATA_SUCCESS', () => {
    it('receives logs lines and cursor', () => {
      mutations[types.RECEIVE_LOGS_DATA_SUCCESS](state, {
        logs: mockLogsResult,
        cursor: mockCursor,
      });

      expect(state.logs).toEqual({
        lines: mockLogsResult,
        isLoading: false,
        cursor: mockCursor,
        isComplete: false,
        fetchError: false,
      });
    });

    it('receives logs lines and a null cursor to indicate the end', () => {
      mutations[types.RECEIVE_LOGS_DATA_SUCCESS](state, {
        logs: mockLogsResult,
        cursor: null,
      });

      expect(state.logs).toEqual({
        lines: mockLogsResult,
        isLoading: false,
        cursor: null,
        isComplete: true,
        fetchError: false,
      });
    });
  });

  describe('RECEIVE_LOGS_DATA_ERROR', () => {
    it('receives log data error and stops loading', () => {
      mutations[types.RECEIVE_LOGS_DATA_ERROR](state);

      expect(state.logs).toEqual({
        lines: [],
        isLoading: false,
        cursor: null,
        isComplete: false,
        fetchError: true,
      });
    });
  });

  describe('REQUEST_LOGS_DATA_PREPEND', () => {
    it('receives logs lines and cursor', () => {
      mutations[types.REQUEST_LOGS_DATA_PREPEND](state);

      expect(state.logs.isLoading).toBe(true);
    });
  });

  describe('RECEIVE_LOGS_DATA_PREPEND_SUCCESS', () => {
    it('receives logs lines and cursor', () => {
      mutations[types.RECEIVE_LOGS_DATA_PREPEND_SUCCESS](state, {
        logs: mockLogsResult,
        cursor: mockCursor,
      });

      expect(state.logs).toEqual({
        lines: mockLogsResult,
        isLoading: false,
        cursor: mockCursor,
        isComplete: false,
        fetchError: false,
      });
    });

    it('receives additional logs lines and a new cursor', () => {
      mutations[types.RECEIVE_LOGS_DATA_PREPEND_SUCCESS](state, {
        logs: mockLogsResult,
        cursor: mockCursor,
      });

      mutations[types.RECEIVE_LOGS_DATA_PREPEND_SUCCESS](state, {
        logs: mockLogsResult,
        cursor: mockNextCursor,
      });

      expect(state.logs).toEqual({
        lines: [...mockLogsResult, ...mockLogsResult],
        isLoading: false,
        cursor: mockNextCursor,
        isComplete: false,
        fetchError: false,
      });
    });

    it('receives logs lines and a null cursor to indicate is complete', () => {
      mutations[types.RECEIVE_LOGS_DATA_PREPEND_SUCCESS](state, {
        logs: mockLogsResult,
        cursor: null,
      });

      expect(state.logs).toEqual({
        lines: mockLogsResult,
        isLoading: false,
        cursor: null,
        isComplete: true,
        fetchError: false,
      });
    });
  });

  describe('RECEIVE_LOGS_DATA_PREPEND_ERROR', () => {
    it('receives logs lines and cursor', () => {
      mutations[types.RECEIVE_LOGS_DATA_PREPEND_ERROR](state);

      expect(state.logs.isLoading).toBe(false);
      expect(state.logs.fetchError).toBe(true);
    });
  });

  describe('SET_CURRENT_POD_NAME', () => {
    it('set current pod name', () => {
      mutations[types.SET_CURRENT_POD_NAME](state, mockPodName);

      expect(state.pods.current).toEqual(mockPodName);
    });
  });

  describe('SET_TIME_RANGE', () => {
    it('sets a default range', () => {
      expect(state.timeRange.selected).toEqual(expect.any(Object));
      expect(state.timeRange.current).toEqual(expect.any(Object));
    });

    it('sets a time range', () => {
      const mockRange = {
        start: '2020-01-10T18:00:00.000Z',
        end: '2020-01-10T10:00:00.000Z',
      };
      mutations[types.SET_TIME_RANGE](state, mockRange);

      expect(state.timeRange.selected).toEqual(mockRange);
      expect(state.timeRange.current).toEqual(mockRange);
    });
  });

  describe('RECEIVE_PODS_DATA_SUCCESS', () => {
    it('receives pods data success', () => {
      mutations[types.RECEIVE_PODS_DATA_SUCCESS](state, mockPods);

      expect(state.pods).toEqual(
        expect.objectContaining({
          options: mockPods,
        }),
      );
    });
  });
  describe('RECEIVE_PODS_DATA_ERROR', () => {
    it('receives pods data error', () => {
      mutations[types.RECEIVE_PODS_DATA_ERROR](state);

      expect(state.pods).toEqual(
        expect.objectContaining({
          options: [],
        }),
      );
    });
  });
});
