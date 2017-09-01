import _ from 'underscore';

function sortMetrics(metrics) {
  return _.chain(metrics).sortBy('weight').sortBy('title').value();
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
          value,
        })),
      })),
    })),
  }));
}

function collate(array, rows = 2) {
  const collatedArray = [];
  let row = [];
  array.forEach((value, index) => {
    row.push(value);
    if ((index + 1) % rows === 0) {
      collatedArray.push(row);
      row = [];
    }
  });
  if (row.length > 0) {
    collatedArray.push(row);
  }
  return collatedArray;
}

export default class MonitoringStore {
  constructor() {
    this.groups = [];
    this.deploymentData = [];
  }

  storeMetrics(groups = []) {
    this.groups = groups.map(group => ({
      ...group,
      metrics: collate(normalizeMetrics(sortMetrics(group.metrics))),
    }));
  }

  storeDeploymentData(deploymentData = []) {
    this.deploymentData = deploymentData;
  }

  getMetricsCount() {
    let metricsCount = 0;
    this.groups.forEach((group) => {
      group.metrics.forEach((metric) => {
        metricsCount = metricsCount += metric.length;
      });
    });
    return metricsCount;
  }
}
