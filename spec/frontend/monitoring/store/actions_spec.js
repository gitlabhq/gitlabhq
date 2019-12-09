import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import Tracking from '~/tracking';
import axios from '~/lib/utils/axios_utils';
import statusCodes from '~/lib/utils/http_status';
import { backOff } from '~/lib/utils/common_utils';
import createFlash from '~/flash';

import store from '~/monitoring/stores';
import * as types from '~/monitoring/stores/mutation_types';
import {
  fetchDashboard,
  receiveMetricsDashboardSuccess,
  receiveMetricsDashboardFailure,
  fetchDeploymentsData,
  fetchEnvironmentsData,
  fetchPrometheusMetrics,
  fetchPrometheusMetric,
  setEndpoints,
  setGettingStartedEmptyState,
} from '~/monitoring/stores/actions';
import storeState from '~/monitoring/stores/state';
import {
  deploymentData,
  environmentData,
  metricsDashboardResponse,
  metricsGroupsAPIResponse,
  dashboardGitResponse,
} from '../mock_data';

jest.mock('~/lib/utils/common_utils');
jest.mock('~/flash');

const resetStore = str => {
  str.replaceState({
    showEmptyState: true,
    emptyState: 'loading',
    groups: [],
  });
};

describe('Monitoring store actions', () => {
  let mock;
  beforeEach(() => {
    mock = new MockAdapter(axios);

    // Mock `backOff` function to remove exponential algorithm delay.
    jest.useFakeTimers();

    backOff.mockImplementation(callback => {
      const q = new Promise((resolve, reject) => {
        const stop = arg => (arg instanceof Error ? reject(arg) : resolve(arg));
        const next = () => callback(next, stop);
        // Define a timeout based on a mock timer
        setTimeout(() => {
          callback(next, stop);
        });
      });
      // Run all resolved promises in chain
      jest.runOnlyPendingTimers();
      return q;
    });
  });
  afterEach(() => {
    resetStore(store);
    mock.reset();

    backOff.mockReset();
    createFlash.mockReset();
  });

  describe('fetchDeploymentsData', () => {
    it('commits RECEIVE_DEPLOYMENTS_DATA_SUCCESS on error', done => {
      const dispatch = jest.fn();
      const { state } = store;
      state.deploymentsEndpoint = '/success';
      mock.onGet(state.deploymentsEndpoint).reply(200, {
        deployments: deploymentData,
      });
      fetchDeploymentsData({
        state,
        dispatch,
      })
        .then(() => {
          expect(dispatch).toHaveBeenCalledWith('receiveDeploymentsDataSuccess', deploymentData);
          done();
        })
        .catch(done.fail);
    });
    it('commits RECEIVE_DEPLOYMENTS_DATA_FAILURE on error', done => {
      const dispatch = jest.fn();
      const { state } = store;
      state.deploymentsEndpoint = '/error';
      mock.onGet(state.deploymentsEndpoint).reply(500);
      fetchDeploymentsData({
        state,
        dispatch,
      })
        .then(() => {
          expect(dispatch).toHaveBeenCalledWith('receiveDeploymentsDataFailure');
          done();
        })
        .catch(done.fail);
    });
  });
  describe('fetchEnvironmentsData', () => {
    it('commits RECEIVE_ENVIRONMENTS_DATA_SUCCESS on error', done => {
      const dispatch = jest.fn();
      const { state } = store;
      state.environmentsEndpoint = '/success';
      mock.onGet(state.environmentsEndpoint).reply(200, {
        environments: environmentData,
      });
      fetchEnvironmentsData({
        state,
        dispatch,
      })
        .then(() => {
          expect(dispatch).toHaveBeenCalledWith('receiveEnvironmentsDataSuccess', environmentData);
          done();
        })
        .catch(done.fail);
    });
    it('commits RECEIVE_ENVIRONMENTS_DATA_FAILURE on error', done => {
      const dispatch = jest.fn();
      const { state } = store;
      state.environmentsEndpoint = '/error';
      mock.onGet(state.environmentsEndpoint).reply(500);
      fetchEnvironmentsData({
        state,
        dispatch,
      })
        .then(() => {
          expect(dispatch).toHaveBeenCalledWith('receiveEnvironmentsDataFailure');
          done();
        })
        .catch(done.fail);
    });
  });
  describe('Set endpoints', () => {
    let mockedState;
    beforeEach(() => {
      mockedState = storeState();
    });
    it('should commit SET_ENDPOINTS mutation', done => {
      testAction(
        setEndpoints,
        {
          metricsEndpoint: 'additional_metrics.json',
          deploymentsEndpoint: 'deployments.json',
          environmentsEndpoint: 'deployments.json',
        },
        mockedState,
        [
          {
            type: types.SET_ENDPOINTS,
            payload: {
              metricsEndpoint: 'additional_metrics.json',
              deploymentsEndpoint: 'deployments.json',
              environmentsEndpoint: 'deployments.json',
            },
          },
        ],
        [],
        done,
      );
    });
  });
  describe('Set empty states', () => {
    let mockedState;
    beforeEach(() => {
      mockedState = storeState();
    });
    it('should commit SET_METRICS_ENDPOINT mutation', done => {
      testAction(
        setGettingStartedEmptyState,
        null,
        mockedState,
        [
          {
            type: types.SET_GETTING_STARTED_EMPTY_STATE,
          },
        ],
        [],
        done,
      );
    });
  });
  describe('fetchDashboard', () => {
    let dispatch;
    let state;
    const response = metricsDashboardResponse;
    beforeEach(() => {
      jest.spyOn(Tracking, 'event');
      dispatch = jest.fn();
      state = storeState();
      state.dashboardEndpoint = '/dashboard';
    });
    it('dispatches receive and success actions', done => {
      const params = {};
      document.body.dataset.page = 'projects:environments:metrics';
      mock.onGet(state.dashboardEndpoint).reply(200, response);
      fetchDashboard(
        {
          state,
          dispatch,
        },
        params,
      )
        .then(() => {
          expect(dispatch).toHaveBeenCalledWith('requestMetricsDashboard');
          expect(dispatch).toHaveBeenCalledWith('receiveMetricsDashboardSuccess', {
            response,
            params,
          });
        })
        .then(() => {
          expect(Tracking.event).toHaveBeenCalledWith(
            document.body.dataset.page,
            'dashboard_fetch',
            {
              label: 'custom_metrics_dashboard',
              property: 'count',
              value: 0,
            },
          );
          done();
        })
        .catch(done.fail);
    });
    it('dispatches failure action', done => {
      const params = {};
      mock.onGet(state.dashboardEndpoint).reply(500);
      fetchDashboard(
        {
          state,
          dispatch,
        },
        params,
      )
        .then(() => {
          expect(dispatch).toHaveBeenCalledWith(
            'receiveMetricsDashboardFailure',
            new Error('Request failed with status code 500'),
          );
          done();
        })
        .catch(done.fail);
    });
  });
  describe('receiveMetricsDashboardSuccess', () => {
    let commit;
    let dispatch;
    let state;
    beforeEach(() => {
      commit = jest.fn();
      dispatch = jest.fn();
      state = storeState();
    });
    it('stores groups ', () => {
      const params = {};
      const response = metricsDashboardResponse;
      receiveMetricsDashboardSuccess(
        {
          state,
          commit,
          dispatch,
        },
        {
          response,
          params,
        },
      );
      expect(commit).toHaveBeenCalledWith(
        types.RECEIVE_METRICS_DATA_SUCCESS,
        metricsDashboardResponse.dashboard.panel_groups,
      );
      expect(dispatch).toHaveBeenCalledWith('fetchPrometheusMetrics', params);
    });
    it('sets the dashboards loaded from the repository', () => {
      const params = {};
      const response = metricsDashboardResponse;
      response.all_dashboards = dashboardGitResponse;
      receiveMetricsDashboardSuccess(
        {
          state,
          commit,
          dispatch,
        },
        {
          response,
          params,
        },
      );
      expect(commit).toHaveBeenCalledWith(types.SET_ALL_DASHBOARDS, dashboardGitResponse);
    });
  });
  describe('receiveMetricsDashboardFailure', () => {
    let commit;
    beforeEach(() => {
      commit = jest.fn();
    });
    it('commits failure action', () => {
      receiveMetricsDashboardFailure({
        commit,
      });
      expect(commit).toHaveBeenCalledWith(types.RECEIVE_METRICS_DATA_FAILURE, undefined);
    });
    it('commits failure action with error', () => {
      receiveMetricsDashboardFailure(
        {
          commit,
        },
        'uh-oh',
      );
      expect(commit).toHaveBeenCalledWith(types.RECEIVE_METRICS_DATA_FAILURE, 'uh-oh');
    });
  });
  describe('fetchPrometheusMetrics', () => {
    let commit;
    let dispatch;
    beforeEach(() => {
      commit = jest.fn();
      dispatch = jest.fn();
    });
    it('commits empty state when state.groups is empty', done => {
      const state = storeState();
      const params = {};
      fetchPrometheusMetrics({ state, commit, dispatch }, params)
        .then(() => {
          expect(commit).toHaveBeenCalledWith(types.SET_NO_DATA_EMPTY_STATE);
          expect(dispatch).not.toHaveBeenCalled();
          expect(createFlash).not.toHaveBeenCalled();
          done();
        })
        .catch(done.fail);
    });
    it('dispatches fetchPrometheusMetric for each panel query', done => {
      const params = {};
      const state = storeState();
      state.dashboard.panel_groups = metricsDashboardResponse.dashboard.panel_groups;
      const metric = state.dashboard.panel_groups[0].panels[0].metrics[0];
      fetchPrometheusMetrics({ state, commit, dispatch }, params)
        .then(() => {
          expect(dispatch).toHaveBeenCalledTimes(3);
          expect(dispatch).toHaveBeenCalledWith('fetchPrometheusMetric', {
            metric,
            params,
          });

          expect(createFlash).not.toHaveBeenCalled();

          done();
        })
        .catch(done.fail);
      done();
    });

    it('dispatches fetchPrometheusMetric for each panel query, handles an error', done => {
      const params = {};
      const state = storeState();
      state.dashboard.panel_groups = metricsDashboardResponse.dashboard.panel_groups;
      const metric = state.dashboard.panel_groups[0].panels[0].metrics[0];

      // Mock having one out of three metrics failing
      dispatch.mockRejectedValueOnce(new Error('Error fetching this metric'));
      dispatch.mockResolvedValue();

      fetchPrometheusMetrics({ state, commit, dispatch }, params)
        .then(() => {
          expect(dispatch).toHaveBeenCalledTimes(3);
          expect(dispatch).toHaveBeenCalledWith('fetchPrometheusMetric', {
            metric,
            params,
          });

          expect(createFlash).toHaveBeenCalledTimes(1);

          done();
        })
        .catch(done.fail);
      done();
    });
  });
  describe('fetchPrometheusMetric', () => {
    const params = {
      start: '2019-08-06T12:40:02.184Z',
      end: '2019-08-06T20:40:02.184Z',
    };
    let commit;
    let metric;
    let state;
    let data;

    beforeEach(() => {
      commit = jest.fn();
      state = storeState();
      [metric] = metricsDashboardResponse.dashboard.panel_groups[0].panels[0].metrics;
      [data] = metricsGroupsAPIResponse[0].panels[0].metrics;
    });

    it('commits result', done => {
      mock.onGet('http://test').reply(200, { data }); // One attempt

      fetchPrometheusMetric({ state, commit }, { metric, params })
        .then(() => {
          expect(commit).toHaveBeenCalledWith(types.SET_QUERY_RESULT, {
            metricId: metric.metric_id,
            result: data.result,
          });

          expect(mock.history.get).toHaveLength(1);
          done();
        })
        .catch(done.fail);
    });

    it('commits result, when waiting for results', done => {
      // Mock multiple attempts while the cache is filling up
      mock.onGet('http://test').replyOnce(statusCodes.NO_CONTENT);
      mock.onGet('http://test').replyOnce(statusCodes.NO_CONTENT);
      mock.onGet('http://test').replyOnce(statusCodes.NO_CONTENT);
      mock.onGet('http://test').reply(200, { data }); // 4th attempt

      const fetch = fetchPrometheusMetric({ state, commit }, { metric, params });

      fetch
        .then(() => {
          expect(commit).toHaveBeenCalledWith(types.SET_QUERY_RESULT, {
            metricId: metric.metric_id,
            result: data.result,
          });
          expect(mock.history.get).toHaveLength(4);
          done();
        })
        .catch(done.fail);
    });

    it('commits failure, when waiting for results and getting a server error', done => {
      // Mock multiple attempts while the cache is filling up and fails
      mock.onGet('http://test').replyOnce(statusCodes.NO_CONTENT);
      mock.onGet('http://test').replyOnce(statusCodes.NO_CONTENT);
      mock.onGet('http://test').replyOnce(statusCodes.NO_CONTENT);
      mock.onGet('http://test').reply(500); // 4th attempt

      fetchPrometheusMetric({ state, commit }, { metric, params })
        .then(() => {
          done.fail();
        })
        .catch(() => {
          expect(commit).not.toHaveBeenCalled();
          expect(mock.history.get).toHaveLength(4);
          done();
        });
    });
  });
});
