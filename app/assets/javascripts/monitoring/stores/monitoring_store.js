import _ from 'underscore';

class MonitoringStore {
  constructor() {
    this.groups = [];
    this.deploymentData = [];
  }

  // eslint-disable-next-line class-methods-use-this
  createArrayRows(metrics = []) {
    const currentMetrics = metrics;
    const availableMetrics = [];
    let metricsRow = [];
    let index = 1;
    Object.keys(currentMetrics).forEach((key) => {
      const metricValues = currentMetrics[key].queries[0].result[0].values;
      if (metricValues != null) {
        const literalMetrics = metricValues.map(metric => ({
          time: new Date(metric[0] * 1000),
          value: metric[1],
        }));
        currentMetrics[key].queries[0].result[0].values = literalMetrics;
        metricsRow.push(currentMetrics[key]);
        if (index % 2 === 0) {
          availableMetrics.push(metricsRow);
          metricsRow = [];
        }
        index = index += 1;
      }
    });
    if (metricsRow.length > 0) {
      availableMetrics.push(metricsRow);
    }
    return availableMetrics;
  }

  storeMetrics(groups = []) {
    this.groups = groups.map((group) => {
      const currentGroup = group;
      currentGroup.metrics = _.chain(group.metrics).sortBy('weight').sortBy('title').value();
      currentGroup.metrics = this.createArrayRows(currentGroup.metrics);
      return currentGroup;
    });
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

export default MonitoringStore;
