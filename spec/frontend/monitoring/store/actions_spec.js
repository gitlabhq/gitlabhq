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
  filterEnvironments,
  setGettingStartedEmptyState,
  duplicateSystemDashboard,
} from '~/monitoring/stores/actions';
import { gqClient, parseEnvironmentsResponse } from '~/monitoring/stores/utils';
import getEnvironments from '~/monitoring/queries/getEnvironments.query.graphql';
import storeState from '~/monitoring/stores/state';
import {
  deploymentData,
  environmentData,
  metricsDashboardResponse,
  metricsDashboardPayload,
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
    const dispatch = jest.fn();
    const { state } = store;
    state.projectPath = 'gitlab-org/gitlab-test';

    afterEach(() => {
      resetStore(store);
      jest.restoreAllMocks();
    });

    it('setting SET_ENVIRONMENTS_FILTER should dispatch fetchEnvironmentsData', () => {
      jest.spyOn(gqClient, 'mutate').mockReturnValue(
        Promise.resolve({
          data: {
            project: {
              data: {
                environments: [],
              },
            },
          },
        }),
      );

      return testAction(
        filterEnvironments,
        {},
        state,
        [
          {
            type: 'SET_ENVIRONMENTS_FILTER',
            payload: {},
          },
        ],
        [
          {
            type: 'fetchEnvironmentsData',
          },
        ],
      );
    });

    it('fetch environments data call takes in search param', () => {
      const mockMutate = jest.spyOn(gqClient, 'mutate');
      const searchTerm = 'Something';
      const mutationVariables = {
        mutation: getEnvironments,
        variables: {
          projectPath: state.projectPath,
          search: searchTerm,
        },
      };
      state.environmentsSearchTerm = searchTerm;
      mockMutate.mockReturnValue(Promise.resolve());

      return fetchEnvironmentsData({
        state,
        dispatch,
      }).then(() => {
        expect(mockMutate).toHaveBeenCalledWith(mutationVariables);
      });
    });

    it('commits RECEIVE_ENVIRONMENTS_DATA_SUCCESS on success', () => {
      jest.spyOn(gqClient, 'mutate').mockReturnValue(
        Promise.resolve({
          data: {
            project: {
              data: {
                environments: environmentData,
              },
            },
          },
        }),
      );

      return fetchEnvironmentsData({
        state,
        dispatch,
      }).then(() => {
        expect(dispatch).toHaveBeenCalledWith(
          'receiveEnvironmentsDataSuccess',
          parseEnvironmentsResponse(environmentData, state.projectPath),
        );
      });
    });

    it('commits RECEIVE_ENVIRONMENTS_DATA_FAILURE on error', () => {
      jest.spyOn(gqClient, 'mutate').mockReturnValue(Promise.reject());

      return fetchEnvironmentsData({
        state,
        dispatch,
      }).then(() => {
        expect(dispatch).toHaveBeenCalledWith('receiveEnvironmentsDataFailure');
      });
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
        },
        mockedState,
        [
          {
            type: types.SET_ENDPOINTS,
            payload: {
              metricsEndpoint: 'additional_metrics.json',
              deploymentsEndpoint: 'deployments.json',
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
      dispatch = jest.fn();
      state = storeState();
      state.dashboardEndpoint = '/dashboard';
    });
    it('on success, dispatches receive and success actions', done => {
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
          done();
        })
        .catch(done.fail);
    });

    describe('on failure', () => {
      let result;
      let errorResponse;
      beforeEach(() => {
        const params = {};
        result = () => {
          mock.onGet(state.dashboardEndpoint).replyOnce(500, errorResponse);
          return fetchDashboard({ state, dispatch }, params);
        };
      });

      it('dispatches a failure action', done => {
        errorResponse = {};
        result()
          .then(() => {
            expect(dispatch).toHaveBeenCalledWith(
              'receiveMetricsDashboardFailure',
              new Error('Request failed with status code 500'),
            );
            expect(createFlash).toHaveBeenCalled();
            done();
          })
          .catch(done.fail);
      });

      it('dispatches a failure action when a message is returned', done => {
        const message = 'Something went wrong with Prometheus!';
        errorResponse = { message };
        result()
          .then(() => {
            expect(dispatch).toHaveBeenCalledWith(
              'receiveMetricsDashboardFailure',
              new Error('Request failed with status code 500'),
            );
            expect(createFlash).toHaveBeenCalledWith(expect.stringContaining(message));
            done();
          })
          .catch(done.fail);
      });

      it('does not show a flash error when showErrorBanner is disabled', done => {
        state.showErrorBanner = false;

        result()
          .then(() => {
            expect(dispatch).toHaveBeenCalledWith(
              'receiveMetricsDashboardFailure',
              new Error('Request failed with status code 500'),
            );
            expect(createFlash).not.toHaveBeenCalled();
            done();
          })
          .catch(done.fail);
      });
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
        metricsDashboardResponse.dashboard,
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
    const params = {};
    let commit;
    let dispatch;
    let state;

    beforeEach(() => {
      jest.spyOn(Tracking, 'event');
      commit = jest.fn();
      dispatch = jest.fn();
      state = storeState();
    });

    it('commits empty state when state.groups is empty', done => {
      const getters = {
        metricsWithData: () => [],
      };
      fetchPrometheusMetrics({ state, commit, dispatch, getters }, params)
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
          expect(dispatch).not.toHaveBeenCalled();
          expect(createFlash).not.toHaveBeenCalled();
          done();
        })
        .catch(done.fail);
    });
    it('dispatches fetchPrometheusMetric for each panel query', done => {
      state.dashboard.panel_groups = metricsDashboardResponse.dashboard.panel_groups;
      const [metric] = state.dashboard.panel_groups[0].panels[0].metrics;
      const getters = {
        metricsWithData: () => [metric.id],
      };

      fetchPrometheusMetrics({ state, commit, dispatch, getters }, params)
        .then(() => {
          expect(dispatch).toHaveBeenCalledWith('fetchPrometheusMetric', {
            metric,
            params,
          });

          expect(Tracking.event).toHaveBeenCalledWith(
            document.body.dataset.page,
            'dashboard_fetch',
            {
              label: 'custom_metrics_dashboard',
              property: 'count',
              value: 1,
            },
          );

          done();
        })
        .catch(done.fail);
      done();
    });

    it('dispatches fetchPrometheusMetric for each panel query, handles an error', done => {
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
    let metric;
    let state;
    let data;

    beforeEach(() => {
      state = storeState();
      [metric] = metricsDashboardResponse.dashboard.panel_groups[0].panels[0].metrics;
      [data] = metricsDashboardPayload.panel_groups[0].panels[0].metrics;
    });

    it('commits result', done => {
      mock.onGet('http://test').reply(200, { data }); // One attempt

      testAction(
        fetchPrometheusMetric,
        { metric, params },
        state,
        [
          {
            type: types.REQUEST_METRIC_RESULT,
            payload: {
              metricId: metric.metric_id,
            },
          },
          {
            type: types.RECEIVE_METRIC_RESULT_SUCCESS,
            payload: {
              metricId: metric.metric_id,
              result: data.result,
            },
          },
        ],
        [],
        () => {
          expect(mock.history.get).toHaveLength(1);
          done();
        },
      ).catch(done.fail);
    });

    it('commits result, when waiting for results', done => {
      // Mock multiple attempts while the cache is filling up
      mock.onGet('http://test').replyOnce(statusCodes.NO_CONTENT);
      mock.onGet('http://test').replyOnce(statusCodes.NO_CONTENT);
      mock.onGet('http://test').replyOnce(statusCodes.NO_CONTENT);
      mock.onGet('http://test').reply(200, { data }); // 4th attempt

      testAction(
        fetchPrometheusMetric,
        { metric, params },
        state,
        [
          {
            type: types.REQUEST_METRIC_RESULT,
            payload: {
              metricId: metric.metric_id,
            },
          },
          {
            type: types.RECEIVE_METRIC_RESULT_SUCCESS,
            payload: {
              metricId: metric.metric_id,
              result: data.result,
            },
          },
        ],
        [],
        () => {
          expect(mock.history.get).toHaveLength(4);
          done();
        },
      ).catch(done.fail);
    });

    it('commits failure, when waiting for results and getting a server error', done => {
      // Mock multiple attempts while the cache is filling up and fails
      mock.onGet('http://test').replyOnce(statusCodes.NO_CONTENT);
      mock.onGet('http://test').replyOnce(statusCodes.NO_CONTENT);
      mock.onGet('http://test').replyOnce(statusCodes.NO_CONTENT);
      mock.onGet('http://test').reply(500); // 4th attempt

      const error = new Error('Request failed with status code 500');

      testAction(
        fetchPrometheusMetric,
        { metric, params },
        state,
        [
          {
            type: types.REQUEST_METRIC_RESULT,
            payload: {
              metricId: metric.metric_id,
            },
          },
          {
            type: types.RECEIVE_METRIC_RESULT_FAILURE,
            payload: {
              metricId: metric.metric_id,
              error,
            },
          },
        ],
        [],
      ).catch(e => {
        expect(mock.history.get).toHaveLength(4);
        expect(e).toEqual(error);
        done();
      });
    });
  });

  describe('duplicateSystemDashboard', () => {
    let state;

    beforeEach(() => {
      state = storeState();
      state.dashboardsEndpoint = '/dashboards.json';
    });

    it('Succesful POST request resolves', done => {
      mock.onPost(state.dashboardsEndpoint).reply(statusCodes.CREATED, {
        dashboard: dashboardGitResponse[1],
      });

      testAction(duplicateSystemDashboard, {}, state, [], [])
        .then(() => {
          expect(mock.history.post).toHaveLength(1);
          done();
        })
        .catch(done.fail);
    });

    it('Succesful POST request resolves to a dashboard', done => {
      const mockCreatedDashboard = dashboardGitResponse[1];

      const params = {
        dashboard: 'my-dashboard',
        fileName: 'file-name.yml',
        branch: 'my-new-branch',
        commitMessage: 'A new commit message',
      };

      const expectedPayload = JSON.stringify({
        dashboard: 'my-dashboard',
        file_name: 'file-name.yml',
        branch: 'my-new-branch',
        commit_message: 'A new commit message',
      });

      mock.onPost(state.dashboardsEndpoint).reply(statusCodes.CREATED, {
        dashboard: mockCreatedDashboard,
      });

      testAction(duplicateSystemDashboard, params, state, [], [])
        .then(result => {
          expect(mock.history.post).toHaveLength(1);
          expect(mock.history.post[0].data).toEqual(expectedPayload);
          expect(result).toEqual(mockCreatedDashboard);

          done();
        })
        .catch(done.fail);
    });

    it('Failed POST request throws an error', done => {
      mock.onPost(state.dashboardsEndpoint).reply(statusCodes.BAD_REQUEST);

      testAction(duplicateSystemDashboard, {}, state, [], []).catch(err => {
        expect(mock.history.post).toHaveLength(1);
        expect(err).toEqual(expect.any(String));

        done();
      });
    });

    it('Failed POST request throws an error with a description', done => {
      const backendErrorMsg = 'This file already exists!';

      mock.onPost(state.dashboardsEndpoint).reply(statusCodes.BAD_REQUEST, {
        error: backendErrorMsg,
      });

      testAction(duplicateSystemDashboard, {}, state, [], []).catch(err => {
        expect(mock.history.post).toHaveLength(1);
        expect(err).toEqual(expect.any(String));
        expect(err).toEqual(expect.stringContaining(backendErrorMsg));

        done();
      });
    });
  });
});
