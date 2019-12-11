import mutations from '~/monitoring/stores/mutations';
import * as types from '~/monitoring/stores/mutation_types';
import state from '~/monitoring/stores/state';
import {
  metricsGroupsAPIResponse,
  deploymentData,
  metricsDashboardResponse,
  dashboardGitResponse,
} from '../mock_data';

describe('Monitoring mutations', () => {
  let stateCopy;

  beforeEach(() => {
    stateCopy = state();
  });
  describe('RECEIVE_METRICS_DATA_SUCCESS', () => {
    let payload;
    const getGroups = () => stateCopy.dashboard.panel_groups;

    beforeEach(() => {
      stateCopy.dashboard.panel_groups = [];
      payload = metricsGroupsAPIResponse;
    });
    it('adds a key to the group', () => {
      mutations[types.RECEIVE_METRICS_DATA_SUCCESS](stateCopy, payload);
      const groups = getGroups();

      expect(groups[0].key).toBe('response-metrics-nginx-ingress-vts--0');
      expect(groups[1].key).toBe('system-metrics-kubernetes--1');
    });
    it('normalizes values', () => {
      mutations[types.RECEIVE_METRICS_DATA_SUCCESS](stateCopy, payload);
      const expectedLabel = 'Pod average';
      const { label, query_range } = getGroups()[1].panels[0].metrics[0];
      expect(label).toEqual(expectedLabel);
      expect(query_range.length).toBeGreaterThan(0);
    });
    it('contains two groups, with panels with a metric each', () => {
      mutations[types.RECEIVE_METRICS_DATA_SUCCESS](stateCopy, payload);

      const groups = getGroups();

      expect(groups).toBeDefined();
      expect(groups).toHaveLength(2);

      expect(groups[0].panels).toHaveLength(1);
      expect(groups[0].panels[0].metrics).toHaveLength(1);

      expect(groups[1].panels).toHaveLength(2);
      expect(groups[1].panels[0].metrics).toHaveLength(1);
      expect(groups[1].panels[1].metrics).toHaveLength(1);
    });
    it('assigns metrics a metric id', () => {
      mutations[types.RECEIVE_METRICS_DATA_SUCCESS](stateCopy, payload);

      const groups = getGroups();

      expect(groups[0].panels[0].metrics[0].metricId).toEqual(
        '1_response_metrics_nginx_ingress_throughput_status_code',
      );
      expect(groups[1].panels[0].metrics[0].metricId).toEqual(
        '17_system_metrics_kubernetes_container_memory_average',
      );
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
  describe('SET_ENDPOINTS', () => {
    it('should set all the endpoints', () => {
      mutations[types.SET_ENDPOINTS](stateCopy, {
        metricsEndpoint: 'additional_metrics.json',
        environmentsEndpoint: 'environments.json',
        deploymentsEndpoint: 'deployments.json',
        dashboardEndpoint: 'dashboard.json',
        projectPath: '/gitlab-org/gitlab-foss',
      });
      expect(stateCopy.metricsEndpoint).toEqual('additional_metrics.json');
      expect(stateCopy.environmentsEndpoint).toEqual('environments.json');
      expect(stateCopy.deploymentsEndpoint).toEqual('deployments.json');
      expect(stateCopy.dashboardEndpoint).toEqual('dashboard.json');
      expect(stateCopy.projectPath).toEqual('/gitlab-org/gitlab-foss');
    });
  });
  describe('SET_QUERY_RESULT', () => {
    const metricId = '12_system_metrics_kubernetes_container_memory_total';
    const result = [
      {
        values: [[0, 1], [1, 1], [1, 3]],
      },
    ];
    const dashboardGroups = metricsDashboardResponse.dashboard.panel_groups;
    const getMetrics = () => stateCopy.dashboard.panel_groups[0].panels[0].metrics;

    beforeEach(() => {
      mutations[types.RECEIVE_METRICS_DATA_SUCCESS](stateCopy, dashboardGroups);
    });
    it('clears empty state', () => {
      expect(stateCopy.showEmptyState).toBe(true);

      mutations[types.SET_QUERY_RESULT](stateCopy, {
        metricId,
        result,
      });

      expect(stateCopy.showEmptyState).toBe(false);
    });

    it('adds results to the store', () => {
      expect(getMetrics()[0].result).toBe(undefined);

      mutations[types.SET_QUERY_RESULT](stateCopy, {
        metricId,
        result,
      });

      expect(getMetrics()[0].result).toHaveLength(result.length);
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
});
