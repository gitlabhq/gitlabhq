import mutations from '~/logs/stores/mutations';
import * as types from '~/logs/stores/mutation_types';

import logsPageState from '~/logs/stores/state';
import {
  mockEnvName,
  mockEnvironments,
  mockPods,
  mockPodName,
  mockLogsResult,
  mockSearch,
} from '../mock_data';

describe('Logs Store Mutations', () => {
  let state;

  beforeEach(() => {
    state = logsPageState();
  });

  it('ensures mutation types are correctly named', () => {
    Object.keys(types).forEach(k => {
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
      });
    });
  });

  describe('REQUEST_LOGS_DATA', () => {
    it('starts loading for logs', () => {
      mutations[types.REQUEST_LOGS_DATA](state);

      expect(state.logs).toEqual(
        expect.objectContaining({
          lines: [],
          isLoading: true,
          isComplete: false,
        }),
      );
    });
  });

  describe('RECEIVE_LOGS_DATA_SUCCESS', () => {
    it('receives logs lines', () => {
      mutations[types.RECEIVE_LOGS_DATA_SUCCESS](state, mockLogsResult);

      expect(state.logs).toEqual(
        expect.objectContaining({
          lines: mockLogsResult,
          isLoading: false,
          isComplete: true,
        }),
      );
    });
  });

  describe('RECEIVE_LOGS_DATA_ERROR', () => {
    it('receives log data error and stops loading', () => {
      mutations[types.RECEIVE_LOGS_DATA_ERROR](state);

      expect(state.logs).toEqual(
        expect.objectContaining({
          lines: [],
          isLoading: false,
          isComplete: true,
        }),
      );
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
      expect(state.timeRange.current).toEqual(expect.any(Object));
    });

    it('sets a time range', () => {
      const mockRange = {
        start: '2020-01-10T18:00:00.000Z',
        end: '2020-01-10T10:00:00.000Z',
      };
      mutations[types.SET_TIME_RANGE](state, mockRange);

      expect(state.timeRange.current).toEqual(mockRange);
    });
  });

  describe('REQUEST_PODS_DATA', () => {
    it('receives log data error and stops loading', () => {
      mutations[types.REQUEST_PODS_DATA](state);

      expect(state.pods).toEqual(
        expect.objectContaining({
          options: [],
        }),
      );
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
