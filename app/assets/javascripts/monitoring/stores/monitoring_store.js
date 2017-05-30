import _ from 'underscore';

class MonitoringStore {
  constructor() {
    if (!MonitoringStore.singleton) {
      this.groups = [];
      this.enoughMetrics = true;
    }
    return MonitoringStore.singleton;
  }

  static createArrayRows(metrics = []) {
    const availableMetrics = [];
    let metricsRow = [];
    let index = 1;
    Object.keys(metrics).forEach((key) => {
      if (typeof metrics[key].queries[0].result[0].values !== 'undefined') {
        metricsRow.push(metrics[key]);
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
    // TODO: Sorted by weight add the name as another modifier
    this.groups = groups.map((group) => {
      const currentGroup = group;
      currentGroup.metrics = _.sortBy(group.metrics, 'weight');
      currentGroup.metrics = MonitoringStore.createArrayRows(currentGroup.metrics);
      return currentGroup;
    });
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
