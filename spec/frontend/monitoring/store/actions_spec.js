import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import Tracking from '~/tracking';
import axios from '~/lib/utils/axios_utils';
import statusCodes from '~/lib/utils/http_status';
import * as commonUtils from '~/lib/utils/common_utils';
import createFlash from '~/flash';
import { defaultTimeRange } from '~/vue_shared/constants';
import { ENVIRONMENT_AVAILABLE_STATE } from '~/monitoring/constants';

import store from '~/monitoring/stores';
import * as types from '~/monitoring/stores/mutation_types';
import {
  fetchDashboard,
  receiveMetricsDashboardSuccess,
  fetchDeploymentsData,
  fetchEnvironmentsData,
  fetchDashboardData,
  fetchAnnotations,
  fetchPrometheusMetric,
  setInitialState,
  filterEnvironments,
  setGettingStartedEmptyState,
  duplicateSystemDashboard,
} from '~/monitoring/stores/actions';
import { gqClient, parseEnvironmentsResponse } from '~/monitoring/stores/utils';
import getEnvironments from '~/monitoring/queries/getEnvironments.query.graphql';
import getAnnotations from '~/monitoring/queries/getAnnotations.query.graphql';
import storeState from '~/monitoring/stores/state';
import {
  deploymentData,
  environmentData,
  annotationsData,
  metricsDashboardResponse,
  metricsDashboardViewModel,
  dashboardGitResponse,
  mockDashboardsErrorResponse,
} from '../mock_data';

jest.mock('~/flash');

const resetStore = str => {
  str.replaceState({
    showEmptyState: true,
    emptyState: 'loading',
    groups: [],
  });
};

describe('Monitoring store actions', () => {
  const { convertObjectPropsToCamelCase } = commonUtils;

  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);

    // Mock `backOff` function to remove exponential algorithm delay.
    jest.useFakeTimers();

    jest.spyOn(commonUtils, 'backOff').mockImplementation(callback => {
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

    commonUtils.backOff.mockReset();
    createFlash.mockReset();
  });

  describe('fetchDeploymentsData', () => {
    it('dispatches receiveDeploymentsDataSuccess on success', () => {
      const { state } = store;
      state.deploymentsEndpoint = '/success';
      mock.onGet(state.deploymentsEndpoint).reply(200, {
        deployments: deploymentData,
      });

      return testAction(
        fetchDeploymentsData,
        null,
        state,
        [],
        [{ type: 'receiveDeploymentsDataSuccess', payload: deploymentData }],
      );
    });
    it('dispatches receiveDeploymentsDataFailure on error', () => {
      const { state } = store;
      state.deploymentsEndpoint = '/error';
      mock.onGet(state.deploymentsEndpoint).reply(500);

      return testAction(
        fetchDeploymentsData,
        null,
        state,
        [],
        [{ type: 'receiveDeploymentsDataFailure' }],
        () => {
          expect(createFlash).toHaveBeenCalled();
        },
      );
    });
  });

  describe('fetchEnvironmentsData', () => {
    const { state } = store;
    state.projectPath = 'gitlab-org/gitlab-test';

    afterEach(() => {
      resetStore(store);
    });

    it('setting SET_ENVIRONMENTS_FILTER should dispatch fetchEnvironmentsData', () => {
      jest.spyOn(gqClient, 'mutate').mockReturnValue({
        data: {
          project: {
            data: {
              environments: [],
            },
          },
        },
      });

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
          states: [ENVIRONMENT_AVAILABLE_STATE],
        },
      };
      state.environmentsSearchTerm = searchTerm;
      mockMutate.mockResolvedValue({});

      return testAction(
        fetchEnvironmentsData,
        null,
        state,
        [],
        [
          { type: 'requestEnvironmentsData' },
          { type: 'receiveEnvironmentsDataSuccess', payload: [] },
        ],
        () => {
          expect(mockMutate).toHaveBeenCalledWith(mutationVariables);
        },
      );
    });

    it('dispatches receiveEnvironmentsDataSuccess on success', () => {
      jest.spyOn(gqClient, 'mutate').mockResolvedValue({
        data: {
          project: {
            data: {
              environments: environmentData,
            },
          },
        },
      });

      return testAction(
        fetchEnvironmentsData,
        null,
        state,
        [],
        [
          { type: 'requestEnvironmentsData' },
          {
            type: 'receiveEnvironmentsDataSuccess',
            payload: parseEnvironmentsResponse(environmentData, state.projectPath),
          },
        ],
      );
    });

    it('dispatches receiveEnvironmentsDataFailure on error', () => {
      jest.spyOn(gqClient, 'mutate').mockRejectedValue({});

      return testAction(
        fetchEnvironmentsData,
        null,
        state,
        [],
        [{ type: 'requestEnvironmentsData' }, { type: 'receiveEnvironmentsDataFailure' }],
      );
    });
  });

  describe('fetchAnnotations', () => {
    const { state } = store;
    state.projectPath = 'gitlab-org/gitlab-test';
    state.currentEnvironmentName = 'production';
    state.currentDashboard = '.gitlab/dashboards/custom_dashboard.yml';

    afterEach(() => {
      resetStore(store);
    });

    it('fetches annotations data and dispatches receiveAnnotationsSuccess', () => {
      const mockMutate = jest.spyOn(gqClient, 'mutate');
      const mutationVariables = {
        mutation: getAnnotations,
        variables: {
          projectPath: state.projectPath,
          environmentName: state.currentEnvironmentName,
          dashboardId: state.currentDashboard,
        },
      };

      mockMutate.mockResolvedValue({
        data: {
          project: {
            environment: {
              metricDashboard: {
                annotations: annotationsData,
              },
            },
          },
        },
      });

      return testAction(
        fetchAnnotations,
        null,
        state,
        [],
        [
          { type: 'requestAnnotations' },
          { type: 'receiveAnnotationsSuccess', payload: annotationsData },
        ],
        () => {
          expect(mockMutate).toHaveBeenCalledWith(mutationVariables);
        },
      );
    });

    it('dispatches receiveAnnotationsFailure if the annotations API call fails', () => {
      const mockMutate = jest.spyOn(gqClient, 'mutate');
      const mutationVariables = {
        mutation: getAnnotations,
        variables: {
          projectPath: state.projectPath,
          environmentName: state.currentEnvironmentName,
          dashboardId: state.currentDashboard,
        },
      };

      mockMutate.mockRejectedValue({});

      return testAction(
        fetchAnnotations,
        null,
        state,
        [],
        [{ type: 'requestAnnotations' }, { type: 'receiveAnnotationsFailure' }],
        () => {
          expect(mockMutate).toHaveBeenCalledWith(mutationVariables);
        },
      );
    });
  });

  describe('Set initial state', () => {
    let mockedState;
    beforeEach(() => {
      mockedState = storeState();
    });
    it('should commit SET_INITIAL_STATE mutation', done => {
      testAction(
        setInitialState,
        {
          metricsEndpoint: 'additional_metrics.json',
          deploymentsEndpoint: 'deployments.json',
        },
        mockedState,
        [
          {
            type: types.SET_INITIAL_STATE,
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
    let commit;
    const response = metricsDashboardResponse;
    beforeEach(() => {
      dispatch = jest.fn();
      commit = jest.fn();
      state = storeState();
      state.dashboardEndpoint = '/dashboard';
    });

    it('on success, dispatches receive and success actions', () => {
      document.body.dataset.page = 'projects:environments:metrics';
      mock.onGet(state.dashboardEndpoint).reply(200, response);

      return testAction(
        fetchDashboard,
        null,
        state,
        [],
        [
          { type: 'requestMetricsDashboard' },
          {
            type: 'receiveMetricsDashboardSuccess',
            payload: { response },
          },
        ],
      );
    });

    describe('on failure', () => {
      let result;
      beforeEach(() => {
        const params = {};
        result = () => {
          mock.onGet(state.dashboardEndpoint).replyOnce(500, mockDashboardsErrorResponse);
          return fetchDashboard({ state, commit, dispatch }, params);
        };
      });

      it('dispatches a failure', done => {
        result()
          .then(() => {
            expect(commit).toHaveBeenCalledWith(
              types.SET_ALL_DASHBOARDS,
              mockDashboardsErrorResponse.all_dashboards,
            );
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
        result()
          .then(() => {
            expect(dispatch).toHaveBeenCalledWith(
              'receiveMetricsDashboardFailure',
              new Error('Request failed with status code 500'),
            );
            expect(createFlash).toHaveBeenCalledWith(
              expect.stringContaining(mockDashboardsErrorResponse.message),
            );
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

    it('stores groups', () => {
      const response = metricsDashboardResponse;
      receiveMetricsDashboardSuccess({ state, commit, dispatch }, { response });
      expect(commit).toHaveBeenCalledWith(
        types.RECEIVE_METRICS_DASHBOARD_SUCCESS,

        metricsDashboardResponse.dashboard,
      );
      expect(dispatch).toHaveBeenCalledWith('fetchDashboardData');
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
  describe('fetchDashboardData', () => {
    let commit;
    let dispatch;
    let state;

    beforeEach(() => {
      jest.spyOn(Tracking, 'event');
      commit = jest.fn();
      dispatch = jest.fn();
      state = storeState();

      state.timeRange = defaultTimeRange;
    });

    it('commits empty state when state.groups is empty', done => {
      const getters = {
        metricsWithData: () => [],
      };
      fetchDashboardData({ state, commit, dispatch, getters })
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
          expect(dispatch).toHaveBeenCalledTimes(1);
          expect(dispatch).toHaveBeenCalledWith('fetchDeploymentsData');

          expect(createFlash).not.toHaveBeenCalled();
          done();
        })
        .catch(done.fail);
    });
    it('dispatches fetchPrometheusMetric for each panel query', done => {
      state.dashboard.panelGroups = convertObjectPropsToCamelCase(
        metricsDashboardResponse.dashboard.panel_groups,
      );

      const [metric] = state.dashboard.panelGroups[0].panels[0].metrics;
      const getters = {
        metricsWithData: () => [metric.id],
      };

      fetchDashboardData({ state, commit, dispatch, getters })
        .then(() => {
          expect(dispatch).toHaveBeenCalledWith('fetchPrometheusMetric', {
            metric,
            defaultQueryParams: {
              start_time: expect.any(String),
              end_time: expect.any(String),
              step: expect.any(Number),
            },
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
      state.dashboard.panelGroups = metricsDashboardViewModel.panelGroups;
      const metric = state.dashboard.panelGroups[0].panels[0].metrics[0];

      dispatch.mockResolvedValueOnce(); // fetchDeploymentsData
      // Mock having one out of four metrics failing
      dispatch.mockRejectedValueOnce(new Error('Error fetching this metric'));
      dispatch.mockResolvedValue();

      fetchDashboardData({ state, commit, dispatch })
        .then(() => {
          expect(dispatch).toHaveBeenCalledTimes(10); // one per metric plus 1 for deployments
          expect(dispatch).toHaveBeenCalledWith('fetchDeploymentsData');
          expect(dispatch).toHaveBeenCalledWith('fetchPrometheusMetric', {
            metric,
            defaultQueryParams: {
              start_time: expect.any(String),
              end_time: expect.any(String),
              step: expect.any(Number),
            },
          });

          expect(createFlash).toHaveBeenCalledTimes(1);

          done();
        })
        .catch(done.fail);
      done();
    });
  });
  describe('fetchPrometheusMetric', () => {
    const defaultQueryParams = {
      start_time: '2019-08-06T12:40:02.184Z',
      end_time: '2019-08-06T20:40:02.184Z',
      step: 60,
    };
    let metric;
    let state;
    let data;

    beforeEach(() => {
      state = storeState();
      [metric] = metricsDashboardResponse.dashboard.panel_groups[0].panels[0].metrics;
      metric = convertObjectPropsToCamelCase(metric, { deep: true });

      data = {
        metricId: metric.metricId,
        result: [1582065167.353, 5, 1582065599.353],
      };
    });

    it('commits result', done => {
      mock.onGet('http://test').reply(200, { data }); // One attempt

      testAction(
        fetchPrometheusMetric,
        { metric, defaultQueryParams },
        state,
        [
          {
            type: types.REQUEST_METRIC_RESULT,
            payload: {
              metricId: metric.metricId,
            },
          },
          {
            type: types.RECEIVE_METRIC_RESULT_SUCCESS,
            payload: {
              metricId: metric.metricId,
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

    describe('without metric defined step', () => {
      const expectedParams = {
        start_time: '2019-08-06T12:40:02.184Z',
        end_time: '2019-08-06T20:40:02.184Z',
        step: 60,
      };

      it('uses calculated step', done => {
        mock.onGet('http://test').reply(200, { data }); // One attempt

        testAction(
          fetchPrometheusMetric,
          { metric, defaultQueryParams },
          state,
          [
            {
              type: types.REQUEST_METRIC_RESULT,
              payload: {
                metricId: metric.metricId,
              },
            },
            {
              type: types.RECEIVE_METRIC_RESULT_SUCCESS,
              payload: {
                metricId: metric.metricId,
                result: data.result,
              },
            },
          ],
          [],
          () => {
            expect(mock.history.get[0].params).toEqual(expectedParams);
            done();
          },
        ).catch(done.fail);
      });
    });

    describe('with metric defined step', () => {
      beforeEach(() => {
        metric.step = 7;
      });

      const expectedParams = {
        start_time: '2019-08-06T12:40:02.184Z',
        end_time: '2019-08-06T20:40:02.184Z',
        step: 7,
      };

      it('uses metric step', done => {
        mock.onGet('http://test').reply(200, { data }); // One attempt

        testAction(
          fetchPrometheusMetric,
          { metric, defaultQueryParams },
          state,
          [
            {
              type: types.REQUEST_METRIC_RESULT,
              payload: {
                metricId: metric.metricId,
              },
            },
            {
              type: types.RECEIVE_METRIC_RESULT_SUCCESS,
              payload: {
                metricId: metric.metricId,
                result: data.result,
              },
            },
          ],
          [],
          () => {
            expect(mock.history.get[0].params).toEqual(expectedParams);
            done();
          },
        ).catch(done.fail);
      });
    });

    it('commits result, when waiting for results', done => {
      // Mock multiple attempts while the cache is filling up
      mock.onGet('http://test').replyOnce(statusCodes.NO_CONTENT);
      mock.onGet('http://test').replyOnce(statusCodes.NO_CONTENT);
      mock.onGet('http://test').replyOnce(statusCodes.NO_CONTENT);
      mock.onGet('http://test').reply(200, { data }); // 4th attempt

      testAction(
        fetchPrometheusMetric,
        { metric, defaultQueryParams },
        state,
        [
          {
            type: types.REQUEST_METRIC_RESULT,
            payload: {
              metricId: metric.metricId,
            },
          },
          {
            type: types.RECEIVE_METRIC_RESULT_SUCCESS,
            payload: {
              metricId: metric.metricId,
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
        { metric, defaultQueryParams },
        state,
        [
          {
            type: types.REQUEST_METRIC_RESULT,
            payload: {
              metricId: metric.metricId,
            },
          },
          {
            type: types.RECEIVE_METRIC_RESULT_FAILURE,
            payload: {
              metricId: metric.metricId,
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
