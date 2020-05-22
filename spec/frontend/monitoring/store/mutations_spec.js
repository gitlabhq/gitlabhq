import httpStatusCodes from '~/lib/utils/http_status';

import mutations from '~/monitoring/stores/mutations';
import * as types from '~/monitoring/stores/mutation_types';
import state from '~/monitoring/stores/state';
import { metricStates } from '~/monitoring/constants';

import { deploymentData, dashboardGitResponse } from '../mock_data';
import { metricsDashboardPayload } from '../fixture_data';

describe('Monitoring mutations', () => {
  let stateCopy;

  beforeEach(() => {
    stateCopy = state();
  });

  describe('RECEIVE_METRICS_DASHBOARD_SUCCESS', () => {
    let payload;
    const getGroups = () => stateCopy.dashboard.panelGroups;

    beforeEach(() => {
      stateCopy.dashboard.panelGroups = [];
      payload = metricsDashboardPayload;
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
        mutations[types.RECEIVE_DASHBOARD_STARRING_SUCCESS](stateCopy, true);

        expect(stateCopy.isUpdatingStarredValue).toBe(false);
        expect(stateCopy.allDashboards[1].starred).toBe(true);
      });

      it('sets a dashboard as unstarred', () => {
        mutations[types.RECEIVE_DASHBOARD_STARRING_SUCCESS](stateCopy, false);

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
    const result = [
      {
        values: [[0, 1], [1, 1], [1, 3]],
      },
    ];
    const dashboard = metricsDashboardPayload;
    const getMetric = () => stateCopy.dashboard.panelGroups[1].panels[0].metrics[0];

    describe('REQUEST_METRIC_RESULT', () => {
      beforeEach(() => {
        mutations[types.RECEIVE_METRICS_DASHBOARD_SUCCESS](stateCopy, dashboard);
      });
      it('stores a loading state on a metric', () => {
        expect(stateCopy.showEmptyState).toBe(true);

        mutations[types.REQUEST_METRIC_RESULT](stateCopy, {
          metricId,
        });

        expect(stateCopy.showEmptyState).toBe(true);
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
      it('clears empty state', () => {
        expect(stateCopy.showEmptyState).toBe(true);

        mutations[types.RECEIVE_METRIC_RESULT_SUCCESS](stateCopy, {
          metricId,
          result,
        });

        expect(stateCopy.showEmptyState).toBe(false);
      });

      it('adds results to the store', () => {
        expect(getMetric().result).toBe(null);

        mutations[types.RECEIVE_METRIC_RESULT_SUCCESS](stateCopy, {
          metricId,
          result,
        });

        expect(getMetric().result).toHaveLength(result.length);
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
      it('maintains the loading state when a metric fails', () => {
        expect(stateCopy.showEmptyState).toBe(true);

        mutations[types.RECEIVE_METRIC_RESULT_FAILURE](stateCopy, {
          metricId,
          error: 'an error',
        });

        expect(stateCopy.showEmptyState).toBe(true);
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

  describe('SET_VARIABLES', () => {
    it('stores an empty variables array when no custom variables are given', () => {
      mutations[types.SET_VARIABLES](stateCopy, {});

      expect(stateCopy.variables).toEqual({});
    });

    it('stores variables in the key key_value format in the array', () => {
      mutations[types.SET_VARIABLES](stateCopy, { pod: 'POD', stage: 'main ops' });

      expect(stateCopy.variables).toEqual({ pod: 'POD', stage: 'main ops' });
    });
  });

  describe('UPDATE_VARIABLES', () => {
    afterEach(() => {
      mutations[types.SET_VARIABLES](stateCopy, {});
    });

    it('updates only the value of the variable in variables', () => {
      mutations[types.SET_VARIABLES](stateCopy, { environment: { value: 'prod', type: 'text' } });
      mutations[types.UPDATE_VARIABLES](stateCopy, { key: 'environment', value: 'new prod' });

      expect(stateCopy.variables).toEqual({ environment: { value: 'new prod', type: 'text' } });
    });
  });
});
