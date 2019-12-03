export const metricsWithData = [15, 16];

export const groups = [
  {
    panels: [
      {
        title: 'Memory Usage (Total)',
        type: 'area-chart',
        y_label: 'Total Memory Used',
        weight: 4,
        metrics: [
          {
            id: 'system_metrics_kubernetes_container_memory_total',
            metric_id: 15,
          },
        ],
      },
      {
        title: 'Core Usage (Total)',
        type: 'area-chart',
        y_label: 'Total Cores',
        weight: 3,
        metrics: [
          {
            id: 'system_metrics_kubernetes_container_cores_total',
            metric_id: 16,
          },
        ],
      },
    ],
  },
];

export const metrics = [
  {
    id: 'system_metrics_kubernetes_container_memory_total',
    metric_id: 15,
  },
  {
    id: 'system_metrics_kubernetes_container_cores_total',
    metric_id: 16,
  },
];

const result = [
  {
    values: [
      ['Mon', 1220],
      ['Tue', 932],
      ['Wed', 901],
      ['Thu', 934],
      ['Fri', 1290],
      ['Sat', 1330],
      ['Sun', 1320],
    ],
  },
];

export const metricsData = [
  {
    metrics: [
      {
        metric_id: 15,
        result,
      },
    ],
  },
  {
    metrics: [
      {
        metric_id: 16,
        result,
      },
    ],
  },
];

export const initialState = {
  monitoringDashboard: {},
  dashboard: {
    panel_groups: [],
  },
  metricsWithData: [],
  useDashboardEndpoint: true,
};
