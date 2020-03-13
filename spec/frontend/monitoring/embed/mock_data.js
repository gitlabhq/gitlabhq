export const metricsWithData = ['15_metric_a', '16_metric_b'];

export const groups = [
  {
    panels: [
      {
        title: 'Memory Usage (Total)',
        type: 'area-chart',
        y_label: 'Total Memory Used',
        metrics: null,
      },
    ],
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
        metricId: '15_metric_a',
        result,
      },
    ],
  },
  {
    metrics: [
      {
        metricId: '16_metric_b',
        result,
      },
    ],
  },
];

export const initialState = () => ({
  dashboard: {
    panel_groups: [],
  },
  useDashboardEndpoint: true,
});
