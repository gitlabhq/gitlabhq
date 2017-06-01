import _ from 'underscore';

class MonitoringStore {
  constructor() {
    if (!MonitoringStore.singleton) {
      this.groups = [];
      this.deploymentData = [];
    }
    return MonitoringStore.singleton;
  }

  static createArrayRows(metrics = []) {
    const currentMetrics = metrics;
    const availableMetrics = [];
    let metricsRow = [];
    let index = 1;
    Object.keys(currentMetrics).forEach((key) => {
      if (typeof currentMetrics[key].queries[0].result[0].values !== 'undefined') {
        const literalMetrics = currentMetrics[key].queries[0].result[0].values.map(metric => ({
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
      currentGroup.metrics = MonitoringStore.createArrayRows(currentGroup.metrics);
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
