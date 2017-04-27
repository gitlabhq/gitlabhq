import _ from 'underscore';

class MonitoringStore {
  constructor() {
    this.groups = [];
    this.enoughMetrics = true;
    return this;
  }

  // TODO: Probably move this to an utility class
  static createArrayRows(metrics = []) {
    const availableMetrics = [];
    let metricsRow = [];
    let index = 1;
    Object.keys(metrics).forEach((key) => {
      metricsRow.push(metrics[key]);
      if (index % 2 === 0) {
        availableMetrics.push(metricsRow);
        metricsRow = [];
      }
      index = index += 1;
    });
    if (metricsRow.length > 0) {
      availableMetrics.push(metricsRow);
    }
    return availableMetrics;
  }

  storeMetrics(groups = []) {
    // we're going to have to sort the groups depending on the weight of each of the graphs
    this.groups = groups.map((group) => {
      const currentGroup = group;
      currentGroup.metrics = _.sortBy(group.metrics, 'weight');
      currentGroup.metrics = MonitoringStore.createArrayRows(currentGroup.metrics);
      return currentGroup;
    });
  }
}

export default MonitoringStore;
