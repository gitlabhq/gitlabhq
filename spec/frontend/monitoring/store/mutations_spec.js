import httpStatusCodes from '~/lib/utils/http_status';

import { dashboardEmptyStates, metricStates } from '~/monitoring/constants';
import * as types from '~/monitoring/stores/mutation_types';
import mutations from '~/monitoring/stores/mutations';
import state from '~/monitoring/stores/state';
import { metricsDashboardPayload } from '../fixture_data';
import { prometheusMatrixMultiResult } from '../graph_data';
import { deploymentData, dashboardGitResponse, storeTextVariables } from '../mock_data';

describe('Monitoring mutations', () => {
  let stateCopy;

  beforeEach(() => {
    stateCopy = state();
  });

  describe('REQUEST_METRICS_DASHBOARD', () => {
    it('sets an empty loading state', () => {
      mutations[types.REQUEST_METRICS_DASHBOARD](stateCopy);

      expect(stateCopy.emptyState).toBe(dashboardEmptyStates.LOADING);
    });
  });

  describe('RECEIVE_METRICS_DASHBOARD_SUCCESS', () => {
    let payload;
    const getGroups = () => stateCopy.dashboard.panelGroups;

    beforeEach(() => {
      stateCopy.dashboard.panelGroups = [];
      payload = metricsDashboardPayload;
    });
    it('sets an empty noData state when the dashboard is empty', () => {
      const emptyDashboardPayload = {
        ...payload,
        panel_groups: [],
      };

      mutations[types.RECEIVE_METRICS_DASHBOARD_SUCCESS](stateCopy, emptyDashboardPayload);
      const groups = getGroups();

      expect(groups).toEqual([]);
      expect(stateCopy.emptyState).toBe(dashboardEmptyStates.NO_DATA);
    });
    it('adds a key to the group', () => {
      mutations[types.RECEIVE_METRICS_DASHBOARD_SUCCESS](stateCopy, payload);
      const groups = getGroups();

      expect(groups[0].key).toBe('system-metrics-kubernetes-0');
      expect(groups[1].key).toBe('response-metrics-nginx-ingress-vts-1');
      expect(groups[2].key).toBe('response-metrics-nginx-ingress-2');
    });
    it('normalizes values', () => {
      mutations[types.RECEIVE_METRICS_DASHBOARD_SUCCESS](stateCopy, payload);
      const expectedLabel = 'Pod average (MB)';

      const { label, queryRange } = getGroups()[0].panels[2].metrics[0];
      expect(label).toEqual(expectedLabel);
      expect(queryRange.length).toBeGreaterThan(0);
    });
    it('contains six groups, with panels with a metric each', () => {
      mutations[types.RECEIVE_METRICS_DASHBOARD_SUCCESS](stateCopy, payload);

      const groups = getGroups();

      expect(groups).toBeDefined();
      expect(groups).toHaveLength(6);

      expect(groups[0].panels).toHaveLength(7);
      expect(groups[0].panels[0].metrics).toHaveLength(1);
      expect(groups[0].panels[1].metrics).toHaveLength(1);
      expect(groups[0].panels[2].metrics).toHaveLength(1);

      expect(groups[1].panels).toHaveLength(3);
      expect(groups[1].panels[0].metrics).toHaveLength(1);
    });
    it('assigns metrics a metric id', () => {
      mutations[types.RECEIVE_METRICS_DASHBOARD_SUCCESS](stateCopy, payload);

      const groups = getGroups();

      expect(groups[0].panels[0].metrics[0].metricId).toEqual(
        'NO_DB_system_metrics_kubernetes_container_memory_total',
      );
      expect(groups[1].panels[0].metrics[0].metricId).toEqual(
        'NO_DB_response_metrics_nginx_ingress_throughput_status_code',
      );
      expect(groups[2].panels[0].metrics[0].metricId).toEqual(
        'NO_DB_response_metrics_nginx_ingress_16_throughput_status_code',
      );
    });
  });

  describe('RECEIVE_METRICS_DASHBOARD_FAILURE', () => {
    it('sets an empty noData state when an empty error occurs', () => {
      mutations[types.RECEIVE_METRICS_DASHBOARD_FAILURE](stateCopy);

      expect(stateCopy.emptyState).toBe(dashboardEmptyStates.NO_DATA);
    });

    it('sets an empty unableToConnect state when an error occurs', () => {
      mutations[types.RECEIVE_METRICS_DASHBOARD_FAILURE](stateCopy, 'myerror');

      expect(stateCopy.emptyState).toBe(dashboardEmptyStates.UNABLE_TO_CONNECT);
    });
  });

  describe('Dashboard starring mutations', () => {
    it('REQUEST_DASHBOARD_STARRING', () => {
      stateCopy = { isUpdatingStarredValue: false };
      mutations[types.REQUEST_DASHBOARD_STARRING](stateCopy);

      expect(stateCopy.isUpdatingStarredValue).toBe(true);
    });

    describe('RECEIVE_DASHBOARD_STARRING_SUCCESS', () => {
      let allDashboards;

      beforeEach(() => {
        allDashboards = [...dashboardGitResponse];
        stateCopy = {
          allDashboards,
          currentDashboard: allDashboards[1].path,
          isUpdatingStarredValue: true,
        };
      });

      it('sets a dashboard as starred', () => {
        mutations[types.RECEIVE_DASHBOARD_STARRING_SUCCESS](stateCopy, {
          selectedDashboard: stateCopy.allDashboards[1],
          newStarredValue: true,
        });

        expect(stateCopy.isUpdatingStarredValue).toBe(false);
        expect(stateCopy.allDashboards[1].starred).toBe(true);
      });

      it('sets a dashboard as unstarred', () => {
        mutations[types.RECEIVE_DASHBOARD_STARRING_SUCCESS](stateCopy, {
          selectedDashboard: stateCopy.allDashboards[1],
          newStarredValue: false,
        });

        expect(stateCopy.isUpdatingStarredValue).toBe(false);
        expect(stateCopy.allDashboards[1].starred).toBe(false);
      });
    });

    it('RECEIVE_DASHBOARD_STARRING_FAILURE', () => {
      stateCopy = { isUpdatingStarredValue: true };
      mutations[types.RECEIVE_DASHBOARD_STARRING_FAILURE](stateCopy);

      expect(stateCopy.isUpdatingStarredValue).toBe(false);
    });
  });

  describe('RECEIVE_DEPLOYMENTS_DATA_SUCCESS', () => {
    it('stores the deployment data', () => {
      stateCopy.deploymentData = [];
      mutations[types.RECEIVE_DEPLOYMENTS_DATA_SUCCESS](stateCopy, deploymentData);
      expect(stateCopy.deploymentData).toBeDefined();
      expect(stateCopy.deploymentData).toHaveLength(3);
      expect(typeof stateCopy.deploymentData[0]).toEqual('object');
    });
  });

  describe('SET_INITIAL_STATE', () => {
    it('should set all the endpoints', () => {
      mutations[types.SET_INITIAL_STATE](stateCopy, {
        deploymentsEndpoint: 'deployments.json',
        dashboardEndpoint: 'dashboard.json',
        projectPath: '/gitlab-org/gitlab-foss',
        currentEnvironmentName: 'production',
      });
      expect(stateCopy.deploymentsEndpoint).toEqual('deployments.json');
      expect(stateCopy.dashboardEndpoint).toEqual('dashboard.json');
      expect(stateCopy.projectPath).toEqual('/gitlab-org/gitlab-foss');
      expect(stateCopy.currentEnvironmentName).toEqual('production');
    });

    it('should not remove previously set properties', () => {
      const defaultLogsPath = stateCopy.logsPath;

      mutations[types.SET_INITIAL_STATE](stateCopy, {
        logsPath: defaultLogsPath,
      });
      mutations[types.SET_INITIAL_STATE](stateCopy, {
        dashboardEndpoint: 'dashboard.json',
      });
      mutations[types.SET_INITIAL_STATE](stateCopy, {
        projectPath: '/gitlab-org/gitlab-foss',
      });
      mutations[types.SET_INITIAL_STATE](stateCopy, {
        currentEnvironmentName: 'canary',
      });

      expect(stateCopy).toMatchObject({
        logsPath: defaultLogsPath,
        dashboardEndpoint: 'dashboard.json',
        projectPath: '/gitlab-org/gitlab-foss',
        currentEnvironmentName: 'canary',
      });
    });

    it('should not update unknown properties', () => {
      mutations[types.SET_INITIAL_STATE](stateCopy, {
        dashboardEndpoint: 'dashboard.json',
        someOtherProperty: 'some invalid value', // someOtherProperty is not allowed
      });

      expect(stateCopy.dashboardEndpoint).toBe('dashboard.json');
      expect(stateCopy.someOtherProperty).toBeUndefined();
    });
  });

  describe('SET_ENDPOINTS', () => {
    it('should set all the endpoints', () => {
      mutations[types.SET_ENDPOINTS](stateCopy, {
        deploymentsEndpoint: 'deployments.json',
        dashboardEndpoint: 'dashboard.json',
        projectPath: '/gitlab-org/gitlab-foss',
      });
      expect(stateCopy.deploymentsEndpoint).toEqual('deployments.json');
      expect(stateCopy.dashboardEndpoint).toEqual('dashboard.json');
      expect(stateCopy.projectPath).toEqual('/gitlab-org/gitlab-foss');
    });

    it('should not remove previously set properties', () => {
      const defaultLogsPath = stateCopy.logsPath;

      mutations[types.SET_ENDPOINTS](stateCopy, {
        logsPath: defaultLogsPath,
      });
      mutations[types.SET_ENDPOINTS](stateCopy, {
        dashboardEndpoint: 'dashboard.json',
      });
      mutations[types.SET_ENDPOINTS](stateCopy, {
        projectPath: '/gitlab-org/gitlab-foss',
      });

      expect(stateCopy).toMatchObject({
        logsPath: defaultLogsPath,
        dashboardEndpoint: 'dashboard.json',
        projectPath: '/gitlab-org/gitlab-foss',
      });
    });

    it('should not update unknown properties', () => {
      mutations[types.SET_ENDPOINTS](stateCopy, {
        dashboardEndpoint: 'dashboard.json',
        someOtherProperty: 'some invalid value', // someOtherProperty is not allowed
      });

      expect(stateCopy.dashboardEndpoint).toBe('dashboard.json');
      expect(stateCopy.someOtherProperty).toBeUndefined();
    });
  });

  describe('Individual panel/metric results', () => {
    const metricId = 'NO_DB_response_metrics_nginx_ingress_throughput_status_code';

    const dashboard = metricsDashboardPayload;
    const getMetric = () => stateCopy.dashboard.panelGroups[1].panels[0].metrics[0];

    describe('REQUEST_METRIC_RESULT', () => {
      beforeEach(() => {
        mutations[types.RECEIVE_METRICS_DASHBOARD_SUCCESS](stateCopy, dashboard);
      });
      it('stores a loading state on a metric', () => {
        mutations[types.REQUEST_METRIC_RESULT](stateCopy, {
          metricId,
        });

        expect(getMetric()).toEqual(
          expect.objectContaining({
            loading: true,
          }),
        );
      });
    });

    describe('RECEIVE_METRIC_RESULT_SUCCESS', () => {
      beforeEach(() => {
        mutations[types.RECEIVE_METRICS_DASHBOARD_SUCCESS](stateCopy, dashboard);
      });

      it('adds results to the store', () => {
        const data = prometheusMatrixMultiResult();

        expect(getMetric().result).toBe(null);

        mutations[types.RECEIVE_METRIC_RESULT_SUCCESS](stateCopy, {
          metricId,
          data,
        });

        expect(getMetric().result).toHaveLength(data.result.length);
        expect(getMetric()).toEqual(
          expect.objectContaining({
            loading: false,
            state: metricStates.OK,
          }),
        );
      });
    });

    describe('RECEIVE_METRIC_RESULT_FAILURE', () => {
      beforeEach(() => {
        mutations[types.RECEIVE_METRICS_DASHBOARD_SUCCESS](stateCopy, dashboard);
      });

      it('stores a timeout error in a metric', () => {
        mutations[types.RECEIVE_METRIC_RESULT_FAILURE](stateCopy, {
          metricId,
          error: { message: 'BACKOFF_TIMEOUT' },
        });

        expect(getMetric()).toEqual(
          expect.objectContaining({
            loading: false,
            result: null,
            state: metricStates.TIMEOUT,
          }),
        );
      });

      it('stores a connection failed error in a metric', () => {
        mutations[types.RECEIVE_METRIC_RESULT_FAILURE](stateCopy, {
          metricId,
          error: {
            response: {
              status: httpStatusCodes.SERVICE_UNAVAILABLE,
            },
          },
        });
        expect(getMetric()).toEqual(
          expect.objectContaining({
            loading: false,
            result: null,
            state: metricStates.CONNECTION_FAILED,
          }),
        );
      });

      it('stores a bad data error in a metric', () => {
        mutations[types.RECEIVE_METRIC_RESULT_FAILURE](stateCopy, {
          metricId,
          error: {
            response: {
              status: httpStatusCodes.BAD_REQUEST,
            },
          },
        });

        expect(getMetric()).toEqual(
          expect.objectContaining({
            loading: false,
            result: null,
            state: metricStates.BAD_QUERY,
          }),
        );
      });

      it('stores an unknown error in a metric', () => {
        mutations[types.RECEIVE_METRIC_RESULT_FAILURE](stateCopy, {
          metricId,
          error: null, // no reason in response
        });

        expect(getMetric()).toEqual(
          expect.objectContaining({
            loading: false,
            result: null,
            state: metricStates.UNKNOWN_ERROR,
          }),
        );
      });
    });
  });

  describe('SET_ALL_DASHBOARDS', () => {
    it('stores `undefined` dashboards as an empty array', () => {
      mutations[types.SET_ALL_DASHBOARDS](stateCopy, undefined);

      expect(stateCopy.allDashboards).toEqual([]);
    });

    it('stores `null` dashboards as an empty array', () => {
      mutations[types.SET_ALL_DASHBOARDS](stateCopy, null);

      expect(stateCopy.allDashboards).toEqual([]);
    });

    it('stores dashboards loaded from the git repository', () => {
      mutations[types.SET_ALL_DASHBOARDS](stateCopy, dashboardGitResponse);
      expect(stateCopy.allDashboards).toEqual(dashboardGitResponse);
    });
  });

  describe('SET_EXPANDED_PANEL', () => {
    it('no expanded panel is set initally', () => {
      expect(stateCopy.expandedPanel.panel).toEqual(null);
      expect(stateCopy.expandedPanel.group).toEqual(null);
    });

    it('sets a panel id as the expanded panel', () => {
      const group = 'group_1';
      const panel = { title: 'A Panel' };
      mutations[types.SET_EXPANDED_PANEL](stateCopy, { group, panel });

      expect(stateCopy.expandedPanel).toEqual({ group, panel });
    });

    it('clears panel as the expanded panel', () => {
      mutations[types.SET_EXPANDED_PANEL](stateCopy, { group: null, panel: null });

      expect(stateCopy.expandedPanel.group).toEqual(null);
      expect(stateCopy.expandedPanel.panel).toEqual(null);
    });
  });

  describe('UPDATE_VARIABLE_VALUE', () => {
    it('updates only the value of the variable in variables', () => {
      stateCopy.variables = storeTextVariables;
      mutations[types.UPDATE_VARIABLE_VALUE](stateCopy, { name: 'textSimple', value: 'New Value' });

      expect(stateCopy.variables[0].value).toEqual('New Value');
    });
  });

  describe('UPDATE_VARIABLE_METRIC_LABEL_VALUES', () => {
    it('updates options in a variable', () => {
      const data = [
        {
          __name__: 'up',
          job: 'prometheus',
          env: 'prd',
        },
        {
          __name__: 'up',
          job: 'prometheus',
          env: 'stg',
        },
        {
          __name__: 'up',
          job: 'node',
          env: 'prod',
        },
        {
          __name__: 'up',
          job: 'node',
          env: 'stg',
        },
      ];

      const variable = {
        options: {},
      };

      mutations[types.UPDATE_VARIABLE_METRIC_LABEL_VALUES](stateCopy, {
        variable,
        label: 'job',
        data,
      });

      expect(variable.options).toEqual({
        values: [
          { text: 'prometheus', value: 'prometheus' },
          { text: 'node', value: 'node' },
        ],
      });
    });
  });

  describe('REQUEST_PANEL_PREVIEW', () => {
    it('saves yml content and resets other preview data', () => {
      const mockYmlContent = 'mock yml content';
      mutations[types.REQUEST_PANEL_PREVIEW](stateCopy, mockYmlContent);

      expect(stateCopy.panelPreviewIsLoading).toBe(true);
      expect(stateCopy.panelPreviewYml).toBe(mockYmlContent);
      expect(stateCopy.panelPreviewGraphData).toBe(null);
      expect(stateCopy.panelPreviewError).toBe(null);
    });
  });

  describe('RECEIVE_PANEL_PREVIEW_SUCCESS', () => {
    it('saves graph data', () => {
      mutations[types.RECEIVE_PANEL_PREVIEW_SUCCESS](stateCopy, {
        title: 'My Title',
        type: 'area-chart',
      });

      expect(stateCopy.panelPreviewIsLoading).toBe(false);
      expect(stateCopy.panelPreviewGraphData).toMatchObject({
        title: 'My Title',
        type: 'area-chart',
      });
      expect(stateCopy.panelPreviewError).toBe(null);
    });
  });

  describe('RECEIVE_PANEL_PREVIEW_FAILURE', () => {
    it('saves graph data', () => {
      mutations[types.RECEIVE_PANEL_PREVIEW_FAILURE](stateCopy, 'Error!');

      expect(stateCopy.panelPreviewIsLoading).toBe(false);
      expect(stateCopy.panelPreviewGraphData).toBe(null);
      expect(stateCopy.panelPreviewError).toBe('Error!');
    });
  });

  describe('panel preview metric', () => {
    const getPreviewMetricAt = (i) => stateCopy.panelPreviewGraphData.metrics[i];

    beforeEach(() => {
      stateCopy.panelPreviewGraphData = {
        title: 'Preview panel title',
        metrics: [
          {
            query: 'query',
          },
        ],
      };
    });

    describe('REQUEST_PANEL_PREVIEW_METRIC_RESULT', () => {
      it('sets the metric to loading for the first time', () => {
        mutations[types.REQUEST_PANEL_PREVIEW_METRIC_RESULT](stateCopy, { index: 0 });

        expect(getPreviewMetricAt(0).loading).toBe(true);
        expect(getPreviewMetricAt(0).state).toBe(metricStates.LOADING);
      });

      it('sets the metric to loading and keeps the result', () => {
        getPreviewMetricAt(0).result = [[0, 1]];
        getPreviewMetricAt(0).state = metricStates.OK;

        mutations[types.REQUEST_PANEL_PREVIEW_METRIC_RESULT](stateCopy, { index: 0 });

        expect(getPreviewMetricAt(0)).toMatchObject({
          loading: true,
          result: [[0, 1]],
          state: metricStates.OK,
        });
      });
    });

    describe('RECEIVE_PANEL_PREVIEW_METRIC_RESULT_SUCCESS', () => {
      it('saves the result in the metric', () => {
        const data = prometheusMatrixMultiResult();

        mutations[types.RECEIVE_PANEL_PREVIEW_METRIC_RESULT_SUCCESS](stateCopy, {
          index: 0,
          data,
        });

        expect(getPreviewMetricAt(0)).toMatchObject({
          loading: false,
          state: metricStates.OK,
          result: expect.any(Array),
        });
        expect(getPreviewMetricAt(0).result).toHaveLength(data.result.length);
      });
    });

    describe('RECEIVE_PANEL_PREVIEW_METRIC_RESULT_FAILURE', () => {
      it('stores an error in the metric', () => {
        mutations[types.RECEIVE_PANEL_PREVIEW_METRIC_RESULT_FAILURE](stateCopy, {
          index: 0,
        });

        expect(getPreviewMetricAt(0).loading).toBe(false);
        expect(getPreviewMetricAt(0).state).toBe(metricStates.UNKNOWN_ERROR);
        expect(getPreviewMetricAt(0).result).toBe(null);

        expect(getPreviewMetricAt(0)).toMatchObject({
          loading: false,
          result: null,
          state: metricStates.UNKNOWN_ERROR,
        });
      });

      it('stores a timeout error in a metric', () => {
        mutations[types.RECEIVE_PANEL_PREVIEW_METRIC_RESULT_FAILURE](stateCopy, {
          index: 0,
          error: { message: 'BACKOFF_TIMEOUT' },
        });

        expect(getPreviewMetricAt(0)).toMatchObject({
          loading: false,
          result: null,
          state: metricStates.TIMEOUT,
        });
      });
    });
  });
});
