import _ from 'underscore';

function sortMetrics(metrics) {
  return _.chain(metrics).sortBy('title').sortBy('weight').value();
}

function normalizeMetrics(metrics) {
  return metrics.map(metric => ({
    ...metric,
    queries: metric.queries.map(query => ({
      ...query,
      result: query.result.map(result => ({
        ...result,
        values: result.values.map(([timestamp, value]) => ({
          time: new Date(timestamp * 1000),
          value: Number(value),
        })),
      })),
    })),
  }));
}

export default class MonitoringStore {
  constructor() {
    this.groups = [];
    this.deploymentData = [];
  }

  storeMetrics(groups = []) {
    this.groups = groups.map(group => ({
      ...group,
      metrics: normalizeMetrics(sortMetrics(group.metrics)),
    }));
  }

  storeDeploymentData(deploymentData = []) {
    this.deploymentData = deploymentData;
  }

  getMetricsCount() {
    return this.groups.reduce((count, group) => count + group.metrics.length, 0);
  }
}
