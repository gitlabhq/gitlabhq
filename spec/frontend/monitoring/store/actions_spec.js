import MockAdapter from 'axios-mock-adapter';
import { backoffMockImplementation } from 'helpers/backoff_helper';
import testAction from 'helpers/vuex_action_helper';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import * as commonUtils from '~/lib/utils/common_utils';
import {
  HTTP_STATUS_BAD_REQUEST,
  HTTP_STATUS_CREATED,
  HTTP_STATUS_INTERNAL_SERVER_ERROR,
  HTTP_STATUS_OK,
  HTTP_STATUS_UNPROCESSABLE_ENTITY,
} from '~/lib/utils/http_status';
import { ENVIRONMENT_AVAILABLE_STATE } from '~/monitoring/constants';

import getAnnotations from '~/monitoring/queries/get_annotations.query.graphql';
import getDashboardValidationWarnings from '~/monitoring/queries/get_dashboard_validation_warnings.query.graphql';
import getEnvironments from '~/monitoring/queries/get_environments.query.graphql';
import { createStore } from '~/monitoring/stores';
import {
  setGettingStartedEmptyState,
  setInitialState,
  setExpandedPanel,
  clearExpandedPanel,
  filterEnvironments,
  fetchData,
  fetchDashboard,
  receiveMetricsDashboardSuccess,
  fetchDashboardData,
  fetchPrometheusMetric,
  fetchDeploymentsData,
  fetchEnvironmentsData,
  fetchAnnotations,
  fetchDashboardValidationWarnings,
  toggleStarredValue,
  duplicateSystemDashboard,
  updateVariablesAndFetchData,
  fetchVariableMetricLabelValues,
  fetchPanelPreview,
} from '~/monitoring/stores/actions';
import * as getters from '~/monitoring/stores/getters';
import * as types from '~/monitoring/stores/mutation_types';
import storeState from '~/monitoring/stores/state';
import {
  gqClient,
  parseEnvironmentsResponse,
  parseAnnotationsResponse,
} from '~/monitoring/stores/utils';
import Tracking from '~/tracking';
import { defaultTimeRange } from '~/vue_shared/constants';
import {
  metricsDashboardResponse,
  metricsDashboardViewModel,
  metricsDashboardPanelCount,
} from '../fixture_data';
import {
  deploymentData,
  environmentData,
  annotationsData,
  dashboardGitResponse,
  mockDashboardsErrorResponse,
} from '../mock_data';

jest.mock('~/alert');

describe('Monitoring store actions', () => {
  const { convertObjectPropsToCamelCase } = commonUtils;

  let mock;
  let store;
  let state;

  let dispatch;
  let commit;

  beforeEach(() => {
    store = createStore({ getters });
    state = store.state.monitoringDashboard;
    mock = new MockAdapter(axios);

    commit = jest.fn();
    dispatch = jest.fn();

    jest.spyOn(commonUtils, 'backOff').mockImplementation(backoffMockImplementation);
  });

  afterEach(() => {
    mock.reset();

    commonUtils.backOff.mockReset();
    createAlert.mockReset();
  });

  // Setup

  describe('setGettingStartedEmptyState', () => {
    it('should commit SET_GETTING_STARTED_EMPTY_STATE mutation', () => {
      return testAction(
        setGettingStartedEmptyState,
        null,
        state,
        [
          {
            type: types.SET_GETTING_STARTED_EMPTY_STATE,
          },
        ],
        [],
      );
    });
  });

  describe('setInitialState', () => {
    it('should commit SET_INITIAL_STATE mutation', () => {
      return testAction(
        setInitialState,
        {
          currentDashboard: '.gitlab/dashboards/dashboard.yml',
          deploymentsEndpoint: 'deployments.json',
        },
        state,
        [
          {
            type: types.SET_INITIAL_STATE,
            payload: {
              currentDashboard: '.gitlab/dashboards/dashboard.yml',
              deploymentsEndpoint: 'deployments.json',
            },
          },
        ],
        [],
      );
    });
  });

  describe('setExpandedPanel', () => {
    it('Sets a panel as expanded', () => {
      const group = 'group_1';
      const panel = { title: 'A Panel' };

      return testAction(
        setExpandedPanel,
        { group, panel },
        state,
        [{ type: types.SET_EXPANDED_PANEL, payload: { group, panel } }],
        [],
      );
    });
  });

  describe('clearExpandedPanel', () => {
    it('Clears a panel as expanded', () => {
      return testAction(
        clearExpandedPanel,
        undefined,
        state,
        [{ type: types.SET_EXPANDED_PANEL, payload: { group: null, panel: null } }],
        [],
      );
    });
  });

  // All Data

  describe('fetchData', () => {
    it('dispatches fetchEnvironmentsData and fetchEnvironmentsData', () => {
      return testAction(
        fetchData,
        null,
        state,
        [],
        [
          { type: 'fetchEnvironmentsData' },
          { type: 'fetchDashboard' },
          { type: 'fetchAnnotations' },
        ],
      );
    });

    it('dispatches when feature metricsDashboardAnnotations is on', () => {
      window.gon = { features: { metricsDashboardAnnotations: true } };

      return testAction(
        fetchData,
        null,
        state,
        [],
        [
          { type: 'fetchEnvironmentsData' },
          { type: 'fetchDashboard' },
          { type: 'fetchAnnotations' },
        ],
      );
    });
  });

  // Metrics dashboard

  describe('fetchDashboard', () => {
    const response = metricsDashboardResponse;
    beforeEach(() => {
      state.dashboardEndpoint = '/dashboard';
    });

    it('on success, dispatches receive and success actions, then fetches dashboard warnings', () => {
      document.body.dataset.page = 'projects:environments:metrics';
      mock.onGet(state.dashboardEndpoint).reply(HTTP_STATUS_OK, response);

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
          { type: 'fetchDashboardValidationWarnings' },
        ],
      );
    });

    describe('on failure', () => {
      let result;
      beforeEach(() => {
        const params = {};
        const localGetters = {
          fullDashboardPath: store.getters['monitoringDashboard/fullDashboardPath'],
        };
        result = () => {
          mock
            .onGet(state.dashboardEndpoint)
            .replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR, mockDashboardsErrorResponse);
          return fetchDashboard({ state, commit, dispatch, getters: localGetters }, params);
        };
      });

      it('dispatches a failure', async () => {
        await result();
        expect(commit).toHaveBeenCalledWith(
          types.SET_ALL_DASHBOARDS,
          mockDashboardsErrorResponse.all_dashboards,
        );
        expect(dispatch).toHaveBeenCalledWith(
          'receiveMetricsDashboardFailure',
          new Error('Request failed with status code 500'),
        );
        expect(createAlert).toHaveBeenCalled();
      });

      it('dispatches a failure action when a message is returned', async () => {
        await result();
        expect(dispatch).toHaveBeenCalledWith(
          'receiveMetricsDashboardFailure',
          new Error('Request failed with status code 500'),
        );
        expect(createAlert).toHaveBeenCalledWith({
          message: expect.stringContaining(mockDashboardsErrorResponse.message),
        });
      });

      it('does not show an alert when showErrorBanner is disabled', async () => {
        state.showErrorBanner = false;

        await result();
        expect(dispatch).toHaveBeenCalledWith(
          'receiveMetricsDashboardFailure',
          new Error('Request failed with status code 500'),
        );
        expect(createAlert).not.toHaveBeenCalled();
      });
    });
  });

  describe('receiveMetricsDashboardSuccess', () => {
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

  // Metrics

  describe('fetchDashboardData', () => {
    beforeEach(() => {
      jest.spyOn(Tracking, 'event');

      state.timeRange = defaultTimeRange;
    });

    it('commits empty state when state.groups is empty', async () => {
      const localGetters = {
        metricsWithData: () => [],
      };
      await fetchDashboardData({ state, commit, dispatch, getters: localGetters });
      expect(Tracking.event).toHaveBeenCalledWith(document.body.dataset.page, 'dashboard_fetch', {
        label: 'custom_metrics_dashboard',
        property: 'count',
        value: 0,
      });
      expect(dispatch).toHaveBeenCalledTimes(2);
      expect(dispatch).toHaveBeenCalledWith('fetchDeploymentsData');
      expect(dispatch).toHaveBeenCalledWith('fetchVariableMetricLabelValues', {
        defaultQueryParams: {
          start_time: expect.any(String),
          end_time: expect.any(String),
          step: expect.any(Number),
        },
      });

      expect(createAlert).not.toHaveBeenCalled();
    });

    it('dispatches fetchPrometheusMetric for each panel query', async () => {
      state.dashboard.panelGroups = convertObjectPropsToCamelCase(
        metricsDashboardResponse.dashboard.panel_groups,
      );

      const [metric] = state.dashboard.panelGroups[0].panels[0].metrics;
      const localGetters = {
        metricsWithData: () => [metric.id],
      };

      await fetchDashboardData({ state, commit, dispatch, getters: localGetters });
      expect(dispatch).toHaveBeenCalledWith('fetchPrometheusMetric', {
        metric,
        defaultQueryParams: {
          start_time: expect.any(String),
          end_time: expect.any(String),
          step: expect.any(Number),
        },
      });

      expect(Tracking.event).toHaveBeenCalledWith(document.body.dataset.page, 'dashboard_fetch', {
        label: 'custom_metrics_dashboard',
        property: 'count',
        value: 1,
      });
    });

    it('dispatches fetchPrometheusMetric for each panel query, handles an error', async () => {
      state.dashboard.panelGroups = metricsDashboardViewModel.panelGroups;
      const metric = state.dashboard.panelGroups[0].panels[0].metrics[0];

      dispatch.mockResolvedValueOnce(); // fetchDeploymentsData
      dispatch.mockResolvedValueOnce(); // fetchVariableMetricLabelValues
      // Mock having one out of four metrics failing
      dispatch.mockRejectedValueOnce(new Error('Error fetching this metric'));
      dispatch.mockResolvedValue();

      await fetchDashboardData({ state, commit, dispatch });
      const defaultQueryParams = {
        start_time: expect.any(String),
        end_time: expect.any(String),
        step: expect.any(Number),
      };

      expect(dispatch).toHaveBeenCalledTimes(metricsDashboardPanelCount + 2); // plus 1 for deployments
      expect(dispatch).toHaveBeenCalledWith('fetchDeploymentsData');
      expect(dispatch).toHaveBeenCalledWith('fetchVariableMetricLabelValues', {
        defaultQueryParams,
      });
      expect(dispatch).toHaveBeenCalledWith('fetchPrometheusMetric', {
        metric,
        defaultQueryParams,
      });

      expect(createAlert).toHaveBeenCalledTimes(1);
    });
  });

  describe('fetchPrometheusMetric', () => {
    const defaultQueryParams = {
      start_time: '2019-08-06T12:40:02.184Z',
      end_time: '2019-08-06T20:40:02.184Z',
      step: 60,
    };
    let metric;
    let data;
    let prometheusEndpointPath;

    beforeEach(() => {
      state = storeState();
      [metric] = metricsDashboardViewModel.panelGroups[0].panels[0].metrics;

      prometheusEndpointPath = metric.prometheusEndpointPath;

      data = {
        metricId: metric.metricId,
        result: [1582065167.353, 5, 1582065599.353],
      };
    });

    it('commits result', () => {
      mock.onGet(prometheusEndpointPath).reply(HTTP_STATUS_OK, { data }); // One attempt

      return testAction(
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
              data,
            },
          },
        ],
        [],
      );
    });

    describe('without metric defined step', () => {
      const expectedParams = {
        start_time: '2019-08-06T12:40:02.184Z',
        end_time: '2019-08-06T20:40:02.184Z',
        step: 60,
      };

      it('uses calculated step', async () => {
        mock.onGet(prometheusEndpointPath).reply(HTTP_STATUS_OK, { data }); // One attempt

        await testAction(
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
                data,
              },
            },
          ],
          [],
        );
        expect(mock.history.get[0].params).toEqual(expectedParams);
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

      it('uses metric step', async () => {
        mock.onGet(prometheusEndpointPath).reply(HTTP_STATUS_OK, { data }); // One attempt

        await testAction(
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
                data,
              },
            },
          ],
          [],
        );
        expect(mock.history.get[0].params).toEqual(expectedParams);
      });
    });

    it('commits failure, when waiting for results and getting a server error', async () => {
      mock.onGet(prometheusEndpointPath).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);

      const error = new Error('Request failed with status code 500');

      await expect(
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
        ),
      ).rejects.toEqual(error);
    });
  });

  // Deployments

  describe('fetchDeploymentsData', () => {
    it('dispatches receiveDeploymentsDataSuccess on success', () => {
      state.deploymentsEndpoint = '/success';
      mock.onGet(state.deploymentsEndpoint).reply(HTTP_STATUS_OK, {
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
      state.deploymentsEndpoint = '/error';
      mock.onGet(state.deploymentsEndpoint).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);

      return testAction(
        fetchDeploymentsData,
        null,
        state,
        [],
        [{ type: 'receiveDeploymentsDataFailure' }],
        () => {
          expect(createAlert).toHaveBeenCalled();
        },
      );
    });
  });

  // Environments

  describe('fetchEnvironmentsData', () => {
    beforeEach(() => {
      state.projectPath = 'gitlab-org/gitlab-test';
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
    beforeEach(() => {
      state.timeRange = {
        start: '2020-04-15T12:54:32.137Z',
        end: '2020-08-15T12:54:32.137Z',
      };
      state.projectPath = 'gitlab-org/gitlab-test';
      state.currentEnvironmentName = 'production';
      state.currentDashboard = '.gitlab/dashboards/custom_dashboard.yml';
      // testAction doesn't have access to getters. The state is passed in as getters
      // instead of the actual getters inside the testAction method implementation.
      // All methods downstream that needs access to getters will throw and error.
      // For that reason, the result of the getter is set as a state variable.
      state.fullDashboardPath = store.getters['monitoringDashboard/fullDashboardPath'];
    });

    it('fetches annotations data and dispatches receiveAnnotationsSuccess', () => {
      const mockMutate = jest.spyOn(gqClient, 'mutate');
      const mutationVariables = {
        mutation: getAnnotations,
        variables: {
          projectPath: state.projectPath,
          environmentName: state.currentEnvironmentName,
          dashboardPath: state.currentDashboard,
          startingFrom: state.timeRange.start,
        },
      };
      const parsedResponse = parseAnnotationsResponse(annotationsData);

      mockMutate.mockResolvedValue({
        data: {
          project: {
            environments: {
              nodes: [
                {
                  metricsDashboard: {
                    annotations: {
                      nodes: parsedResponse,
                    },
                  },
                },
              ],
            },
          },
        },
      });

      return testAction(
        fetchAnnotations,
        null,
        state,
        [],
        [{ type: 'receiveAnnotationsSuccess', payload: parsedResponse }],
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
          dashboardPath: state.currentDashboard,
          startingFrom: state.timeRange.start,
        },
      };

      mockMutate.mockRejectedValue({});

      return testAction(
        fetchAnnotations,
        null,
        state,
        [],
        [{ type: 'receiveAnnotationsFailure' }],
        () => {
          expect(mockMutate).toHaveBeenCalledWith(mutationVariables);
        },
      );
    });
  });

  describe('fetchDashboardValidationWarnings', () => {
    let mockMutate;
    let mutationVariables;

    beforeEach(() => {
      state.projectPath = 'gitlab-org/gitlab-test';
      state.currentEnvironmentName = 'production';
      state.currentDashboard = '.gitlab/dashboards/dashboard_with_warnings.yml';
      // testAction doesn't have access to getters. The state is passed in as getters
      // instead of the actual getters inside the testAction method implementation.
      // All methods downstream that needs access to getters will throw and error.
      // For that reason, the result of the getter is set as a state variable.
      state.fullDashboardPath = store.getters['monitoringDashboard/fullDashboardPath'];

      mockMutate = jest.spyOn(gqClient, 'mutate');
      mutationVariables = {
        mutation: getDashboardValidationWarnings,
        variables: {
          projectPath: state.projectPath,
          environmentName: state.currentEnvironmentName,
          dashboardPath: state.fullDashboardPath,
        },
      };
    });

    it('dispatches receiveDashboardValidationWarningsSuccess with true payload when there are warnings', () => {
      mockMutate.mockResolvedValue({
        data: {
          project: {
            id: 'gid://gitlab/Project/29',
            environments: {
              nodes: [
                {
                  name: 'production',
                  metricsDashboard: {
                    path: '.gitlab/dashboards/dashboard_errors_test.yml',
                    schemaValidationWarnings: ["unit: can't be blank"],
                  },
                },
              ],
            },
          },
        },
      });

      return testAction(
        fetchDashboardValidationWarnings,
        null,
        state,
        [],
        [{ type: 'receiveDashboardValidationWarningsSuccess', payload: true }],
        () => {
          expect(mockMutate).toHaveBeenCalledWith(mutationVariables);
        },
      );
    });

    it('dispatches receiveDashboardValidationWarningsSuccess with false payload when there are no warnings', () => {
      mockMutate.mockResolvedValue({
        data: {
          project: {
            id: 'gid://gitlab/Project/29',
            environments: {
              nodes: [
                {
                  name: 'production',
                  metricsDashboard: {
                    path: '.gitlab/dashboards/dashboard_errors_test.yml',
                    schemaValidationWarnings: [],
                  },
                },
              ],
            },
          },
        },
      });

      return testAction(
        fetchDashboardValidationWarnings,
        null,
        state,
        [],
        [{ type: 'receiveDashboardValidationWarningsSuccess', payload: false }],
        () => {
          expect(mockMutate).toHaveBeenCalledWith(mutationVariables);
        },
      );
    });

    it('dispatches receiveDashboardValidationWarningsSuccess with false payload when the response is empty', () => {
      mockMutate.mockResolvedValue({
        data: {
          project: null,
        },
      });

      return testAction(
        fetchDashboardValidationWarnings,
        null,
        state,
        [],
        [{ type: 'receiveDashboardValidationWarningsSuccess', payload: false }],
        () => {
          expect(mockMutate).toHaveBeenCalledWith(mutationVariables);
        },
      );
    });

    it('dispatches receiveDashboardValidationWarningsFailure if the warnings API call fails', () => {
      mockMutate.mockRejectedValue({});

      return testAction(
        fetchDashboardValidationWarnings,
        null,
        state,
        [],
        [{ type: 'receiveDashboardValidationWarningsFailure' }],
        () => {
          expect(mockMutate).toHaveBeenCalledWith(mutationVariables);
        },
      );
    });
  });

  // Dashboard manipulation

  describe('toggleStarredValue', () => {
    let unstarredDashboard;
    let starredDashboard;

    beforeEach(() => {
      state.isUpdatingStarredValue = false;
      [unstarredDashboard, starredDashboard] = dashboardGitResponse;
    });

    it('performs no changes if no dashboard is selected', () => {
      return testAction(toggleStarredValue, null, state, [], []);
    });

    it('performs no changes if already changing starred value', () => {
      state.selectedDashboard = unstarredDashboard;
      state.isUpdatingStarredValue = true;
      return testAction(toggleStarredValue, null, state, [], []);
    });

    it('stars dashboard if it is not starred', () => {
      state.selectedDashboard = unstarredDashboard;
      mock.onPost(unstarredDashboard.user_starred_path).reply(HTTP_STATUS_OK);

      return testAction(toggleStarredValue, null, state, [
        { type: types.REQUEST_DASHBOARD_STARRING },
        {
          type: types.RECEIVE_DASHBOARD_STARRING_SUCCESS,
          payload: {
            newStarredValue: true,
            selectedDashboard: unstarredDashboard,
          },
        },
      ]);
    });

    it('unstars dashboard if it is starred', () => {
      state.selectedDashboard = starredDashboard;
      mock.onPost(starredDashboard.user_starred_path).reply(HTTP_STATUS_OK);

      return testAction(toggleStarredValue, null, state, [
        { type: types.REQUEST_DASHBOARD_STARRING },
        { type: types.RECEIVE_DASHBOARD_STARRING_FAILURE },
      ]);
    });
  });

  describe('duplicateSystemDashboard', () => {
    beforeEach(() => {
      state.dashboardsEndpoint = '/dashboards.json';
    });

    it('Succesful POST request resolves', async () => {
      mock.onPost(state.dashboardsEndpoint).reply(HTTP_STATUS_CREATED, {
        dashboard: dashboardGitResponse[1],
      });

      await testAction(duplicateSystemDashboard, {}, state, [], []);
      expect(mock.history.post).toHaveLength(1);
    });

    it('Succesful POST request resolves to a dashboard', async () => {
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

      mock.onPost(state.dashboardsEndpoint).reply(HTTP_STATUS_CREATED, {
        dashboard: mockCreatedDashboard,
      });

      const result = await testAction(duplicateSystemDashboard, params, state, [], []);
      expect(mock.history.post).toHaveLength(1);
      expect(mock.history.post[0].data).toEqual(expectedPayload);
      expect(result).toEqual(mockCreatedDashboard);
    });

    it('Failed POST request throws an error', async () => {
      mock.onPost(state.dashboardsEndpoint).reply(HTTP_STATUS_BAD_REQUEST);

      await expect(testAction(duplicateSystemDashboard, {}, state, [], [])).rejects.toEqual(
        'There was an error creating the dashboard.',
      );
      expect(mock.history.post).toHaveLength(1);
    });

    it('Failed POST request throws an error with a description', async () => {
      const backendErrorMsg = 'This file already exists!';

      mock.onPost(state.dashboardsEndpoint).reply(HTTP_STATUS_BAD_REQUEST, {
        error: backendErrorMsg,
      });

      await expect(testAction(duplicateSystemDashboard, {}, state, [], [])).rejects.toEqual(
        `There was an error creating the dashboard. ${backendErrorMsg}`,
      );
      expect(mock.history.post).toHaveLength(1);
    });
  });

  // Variables manipulation

  describe('updateVariablesAndFetchData', () => {
    it('should commit UPDATE_VARIABLE_VALUE mutation and fetch data', () => {
      return testAction(
        updateVariablesAndFetchData,
        { pod: 'POD' },
        state,
        [
          {
            type: types.UPDATE_VARIABLE_VALUE,
            payload: { pod: 'POD' },
          },
        ],
        [
          {
            type: 'fetchDashboardData',
          },
        ],
      );
    });
  });

  describe('fetchVariableMetricLabelValues', () => {
    const variable = {
      type: 'metric_label_values',
      name: 'label1',
      options: {
        prometheusEndpointPath: '/series?match[]=metric_name',
        label: 'job',
      },
    };

    const defaultQueryParams = {
      start_time: '2019-08-06T12:40:02.184Z',
      end_time: '2019-08-06T20:40:02.184Z',
    };

    beforeEach(() => {
      state = {
        ...state,
        timeRange: defaultTimeRange,
        variables: [variable],
      };
    });

    it('should commit UPDATE_VARIABLE_METRIC_LABEL_VALUES mutation and fetch data', () => {
      const data = [
        {
          __name__: 'up',
          job: 'prometheus',
        },
        {
          __name__: 'up',
          job: 'POD',
        },
      ];

      mock.onGet('/series?match[]=metric_name').reply(HTTP_STATUS_OK, {
        status: 'success',
        data,
      });

      return testAction(
        fetchVariableMetricLabelValues,
        { defaultQueryParams },
        state,
        [
          {
            type: types.UPDATE_VARIABLE_METRIC_LABEL_VALUES,
            payload: { variable, label: 'job', data },
          },
        ],
        [],
      );
    });

    it('should notify the user that dynamic options were not loaded', () => {
      mock.onGet('/series?match[]=metric_name').reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);

      return testAction(fetchVariableMetricLabelValues, { defaultQueryParams }, state, [], []).then(
        () => {
          expect(createAlert).toHaveBeenCalledTimes(1);
          expect(createAlert).toHaveBeenCalledWith({
            message: expect.stringContaining('error getting options for variable "label1"'),
          });
        },
      );
    });
  });

  describe('fetchPanelPreview', () => {
    const panelPreviewEndpoint = '/builder.json';
    const mockYmlContent = 'mock yml content';

    beforeEach(() => {
      state.panelPreviewEndpoint = panelPreviewEndpoint;
    });

    it('should not commit or dispatch if payload is empty', () => {
      testAction(fetchPanelPreview, '', state, [], []);
    });

    it('should store the panel and fetch metric results', () => {
      const mockPanel = {
        title: 'Go heap size',
        type: 'area-chart',
      };

      mock
        .onPost(panelPreviewEndpoint, { panel_yaml: mockYmlContent })
        .reply(HTTP_STATUS_OK, mockPanel);

      testAction(
        fetchPanelPreview,
        mockYmlContent,
        state,
        [
          { type: types.SET_PANEL_PREVIEW_IS_SHOWN, payload: true },
          { type: types.REQUEST_PANEL_PREVIEW, payload: mockYmlContent },
          { type: types.RECEIVE_PANEL_PREVIEW_SUCCESS, payload: mockPanel },
        ],
        [{ type: 'fetchPanelPreviewMetrics' }],
      );
    });

    it('should display a validation error when the backend cannot process the yml', () => {
      const mockErrorMsg = 'Each "metric" must define one of :query or :query_range';

      mock
        .onPost(panelPreviewEndpoint, { panel_yaml: mockYmlContent })
        .reply(HTTP_STATUS_UNPROCESSABLE_ENTITY, {
          message: mockErrorMsg,
        });

      testAction(fetchPanelPreview, mockYmlContent, state, [
        { type: types.SET_PANEL_PREVIEW_IS_SHOWN, payload: true },
        { type: types.REQUEST_PANEL_PREVIEW, payload: mockYmlContent },
        { type: types.RECEIVE_PANEL_PREVIEW_FAILURE, payload: mockErrorMsg },
      ]);
    });

    it('should display a generic error when the backend fails', () => {
      mock
        .onPost(panelPreviewEndpoint, { panel_yaml: mockYmlContent })
        .reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);

      testAction(fetchPanelPreview, mockYmlContent, state, [
        { type: types.SET_PANEL_PREVIEW_IS_SHOWN, payload: true },
        { type: types.REQUEST_PANEL_PREVIEW, payload: mockYmlContent },
        {
          type: types.RECEIVE_PANEL_PREVIEW_FAILURE,
          payload: 'Request failed with status code 500',
        },
      ]);
    });
  });
});
