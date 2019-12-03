import mutations from '~/monitoring/stores/mutations';
import * as types from '~/monitoring/stores/mutation_types';
import state from '~/monitoring/stores/state';
import {
  metricsGroupsAPIResponse,
  deploymentData,
  metricsDashboardResponse,
  dashboardGitResponse,
} from '../mock_data';
import { uniqMetricsId } from '~/monitoring/stores/utils';

describe('Monitoring mutations', () => {
  let stateCopy;
  beforeEach(() => {
    stateCopy = state();
  });
  describe('RECEIVE_METRICS_DATA_SUCCESS', () => {
    let groups;
    beforeEach(() => {
      stateCopy.dashboard.panel_groups = [];
      groups = metricsGroupsAPIResponse;
    });
    it('adds a key to the group', () => {
      mutations[types.RECEIVE_METRICS_DATA_SUCCESS](stateCopy, groups);
      expect(stateCopy.dashboard.panel_groups[0].key).toBe('system-metrics-kubernetes--0');
    });
    it('normalizes values', () => {
      mutations[types.RECEIVE_METRICS_DATA_SUCCESS](stateCopy, groups);
      const expectedLabel = 'Pod average';
      const { label, query_range } = stateCopy.dashboard.panel_groups[0].panels[0].metrics[0];
      expect(label).toEqual(expectedLabel);
      expect(query_range.length).toBeGreaterThan(0);
    });
    it('contains one group, which it has two panels and one metrics property', () => {
      mutations[types.RECEIVE_METRICS_DATA_SUCCESS](stateCopy, groups);
      expect(stateCopy.dashboard.panel_groups).toBeDefined();
      expect(stateCopy.dashboard.panel_groups.length).toEqual(1);
      expect(stateCopy.dashboard.panel_groups[0].panels.length).toEqual(2);
      expect(stateCopy.dashboard.panel_groups[0].panels[0].metrics.length).toEqual(1);
      expect(stateCopy.dashboard.panel_groups[0].panels[1].metrics.length).toEqual(1);
    });
    it('assigns metrics a metric id', () => {
      mutations[types.RECEIVE_METRICS_DATA_SUCCESS](stateCopy, groups);
      expect(stateCopy.dashboard.panel_groups[0].panels[0].metrics[0].metricId).toEqual(
        '17_system_metrics_kubernetes_container_memory_average',
      );
    });
  });

  describe('RECEIVE_DEPLOYMENTS_DATA_SUCCESS', () => {
    it('stores the deployment data', () => {
      stateCopy.deploymentData = [];
      mutations[types.RECEIVE_DEPLOYMENTS_DATA_SUCCESS](stateCopy, deploymentData);
      expect(stateCopy.deploymentData).toBeDefined();
      expect(stateCopy.deploymentData.length).toEqual(3);
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
    const metricId = 12;
    const id = 'system_metrics_kubernetes_container_memory_total';
    const result = [
      {
        values: [[0, 1], [1, 1], [1, 3]],
      },
    ];
    beforeEach(() => {
      const dashboardGroups = metricsDashboardResponse.dashboard.panel_groups;
      mutations[types.RECEIVE_METRICS_DATA_SUCCESS](stateCopy, dashboardGroups);
    });
    it('clears empty state', () => {
      mutations[types.SET_QUERY_RESULT](stateCopy, {
        metricId,
        result,
      });
      expect(stateCopy.showEmptyState).toBe(false);
    });
    it('sets metricsWithData value', () => {
      const uniqId = uniqMetricsId({
        metric_id: metricId,
        id,
      });
      mutations[types.SET_QUERY_RESULT](stateCopy, {
        metricId: uniqId,
        result,
      });
      expect(stateCopy.metricsWithData).toEqual([uniqId]);
    });
    it('does not store empty results', () => {
      mutations[types.SET_QUERY_RESULT](stateCopy, {
        metricId,
        result: [],
      });
      expect(stateCopy.metricsWithData).toEqual([]);
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
