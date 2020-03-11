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
} from '~/logs/stores/actions';

import { defaultTimeRange } from '~/monitoring/constants';

import axios from '~/lib/utils/axios_utils';
import flash from '~/flash';

import {
  mockProjectPath,
  mockPodName,
  mockEnvironmentsEndpoint,
  mockEnvironments,
  mockPods,
  mockLogsResult,
  mockEnvName,
  mockSearch,
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
      testAction(setInitData, { environmentName: mockEnvName, podName: mockPodName }, state, [
        { type: types.SET_PROJECT_ENVIRONMENT, payload: mockEnvName },
        { type: types.SET_CURRENT_POD_NAME, payload: mockPodName },
      ]));
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

  describe('fetchLogs', () => {
    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.reset();
    });

    it('should commit logs and pod data when there is pod name defined', () => {
      state.environments.options = mockEnvironments;
      state.environments.current = mockEnvName;
      state.pods.current = mockPodName;

      const endpoint = '/dummy_logs_path.json';

      mock
        .onGet(endpoint, {
          params: {
            pod_name: mockPodName,
            ...mockDefaultRange,
          },
        })
        .reply(200, {
          pod_name: mockPodName,
          pods: mockPods,
          logs: mockLogsResult,
        });

      mock.onGet(endpoint).replyOnce(202); // mock reactive cache

      return testAction(
        fetchLogs,
        null,
        state,
        [
          { type: types.REQUEST_PODS_DATA },
          { type: types.REQUEST_LOGS_DATA },
          { type: types.SET_CURRENT_POD_NAME, payload: mockPodName },
          { type: types.RECEIVE_PODS_DATA_SUCCESS, payload: mockPods },
          { type: types.RECEIVE_LOGS_DATA_SUCCESS, payload: mockLogsResult },
        ],
        [],
      );
    });

    it('should commit logs and pod data when there is pod name defined and a non-default date range', () => {
      state.projectPath = mockProjectPath;
      state.environments.options = mockEnvironments;
      state.environments.current = mockEnvName;
      state.pods.current = mockPodName;
      state.timeRange.current = mockFixedRange;

      const endpoint = '/dummy_logs_path.json';

      mock
        .onGet(endpoint, {
          params: {
            pod_name: mockPodName,
            start: mockFixedRange.start,
            end: mockFixedRange.end,
          },
        })
        .reply(200, {
          pod_name: mockPodName,
          pods: mockPods,
          logs: mockLogsResult,
        });

      return testAction(
        fetchLogs,
        null,
        state,
        [
          { type: types.REQUEST_PODS_DATA },
          { type: types.REQUEST_LOGS_DATA },
          { type: types.SET_CURRENT_POD_NAME, payload: mockPodName },
          { type: types.RECEIVE_PODS_DATA_SUCCESS, payload: mockPods },
          { type: types.RECEIVE_LOGS_DATA_SUCCESS, payload: mockLogsResult },
        ],
        [],
      );
    });

    it('should commit logs and pod data when there is pod name and search and a faulty date range', () => {
      state.environments.options = mockEnvironments;
      state.environments.current = mockEnvName;
      state.pods.current = mockPodName;
      state.search = mockSearch;
      state.timeRange.current = 'INVALID_TIME_RANGE';

      const endpoint = '/dummy_logs_path.json';

      mock
        .onGet(endpoint, {
          params: {
            pod_name: mockPodName,
            search: mockSearch,
          },
        })
        .reply(200, {
          pod_name: mockPodName,
          pods: mockPods,
          logs: mockLogsResult,
        });

      mock.onGet(endpoint).replyOnce(202); // mock reactive cache

      return testAction(
        fetchLogs,
        null,
        state,
        [
          { type: types.REQUEST_PODS_DATA },
          { type: types.REQUEST_LOGS_DATA },
          { type: types.SET_CURRENT_POD_NAME, payload: mockPodName },
          { type: types.RECEIVE_PODS_DATA_SUCCESS, payload: mockPods },
          { type: types.RECEIVE_LOGS_DATA_SUCCESS, payload: mockLogsResult },
        ],
        [],
        () => {
          // Warning about time ranges was issued
          expect(flash).toHaveBeenCalledTimes(1);
          expect(flash).toHaveBeenCalledWith(expect.any(String), 'warning');
        },
      );
    });

    it('should commit logs and pod data when no pod name defined', done => {
      state.environments.options = mockEnvironments;
      state.environments.current = mockEnvName;

      const endpoint = '/dummy_logs_path.json';

      mock.onGet(endpoint, { params: { ...mockDefaultRange } }).reply(200, {
        pod_name: mockPodName,
        pods: mockPods,
        logs: mockLogsResult,
      });
      mock.onGet(endpoint).replyOnce(202); // mock reactive cache

      testAction(
        fetchLogs,
        null,
        state,
        [
          { type: types.REQUEST_PODS_DATA },
          { type: types.REQUEST_LOGS_DATA },
          { type: types.SET_CURRENT_POD_NAME, payload: mockPodName },
          { type: types.RECEIVE_PODS_DATA_SUCCESS, payload: mockPods },
          { type: types.RECEIVE_LOGS_DATA_SUCCESS, payload: mockLogsResult },
        ],
        [],
        done,
      );
    });

    it('should commit logs and pod errors when backend fails', () => {
      state.environments.options = mockEnvironments;
      state.environments.current = mockEnvName;

      const endpoint = `/${mockProjectPath}/-/logs/elasticsearch.json?environment_name=${mockEnvName}`;
      mock.onGet(endpoint).replyOnce(500);

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
          expect(flash).toHaveBeenCalledTimes(1);
        },
      );
    });
  });
});
