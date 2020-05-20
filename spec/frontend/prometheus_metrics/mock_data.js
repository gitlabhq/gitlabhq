export const metrics1 = [
  {
    edit_path: '/root/prometheus-test/prometheus/metrics/3/edit',
    id: 3,
    title: 'Requests',
    group: 'Business',
  },
  {
    edit_path: '/root/prometheus-test/prometheus/metrics/2/edit',
    id: 2,
    title: 'Sales by the hour',
    group: 'Business',
  },
  {
    edit_path: '/root/prometheus-test/prometheus/metrics/1/edit',
    id: 1,
    title: 'Requests',
    group: 'Business',
  },
];

export const metrics2 = [
  {
    group: 'Kubernetes',
    priority: 1,
    active_metrics: 4,
    metrics_missing_requirements: 0,
  },
  {
    group: 'HAProxy',
    priority: 2,
    active_metrics: 3,
    metrics_missing_requirements: 0,
  },
  {
    group: 'Apache',
    priority: 3,
    active_metrics: 5,
    metrics_missing_requirements: 0,
  },
];

export const missingVarMetrics = [
  {
    group: 'Kubernetes',
    priority: 1,
    active_metrics: 4,
    metrics_missing_requirements: 0,
  },
  {
    group: 'HAProxy',
    priority: 2,
    active_metrics: 3,
    metrics_missing_requirements: 1,
  },
  {
    group: 'Apache',
    priority: 3,
    active_metrics: 5,
    metrics_missing_requirements: 3,
  },
];
