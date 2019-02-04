import _ from 'underscore';

function sortMetrics(metrics) {
  return _.chain(metrics)
    .sortBy('title')
    .sortBy('weight')
    .value();
}

function checkQueryEmptyData(query) {
  return {
    ...query,
    result: query.result.filter(timeSeries => {
      const newTimeSeries = timeSeries;
      const hasValue = series =>
        !Number.isNaN(series[1]) && (series[1] !== null || series[1] !== undefined);
      const hasNonNullValue = timeSeries.values.find(hasValue);

      newTimeSeries.values = hasNonNullValue ? newTimeSeries.values : [];

      return newTimeSeries.values.length > 0;
    }),
  };
}

function removeTimeSeriesNoData(queries) {
  return queries.reduce((series, query) => series.concat(checkQueryEmptyData(query)), []);
}

function normalizeMetrics(metrics) {
  return metrics.map(metric => {
    const queries = metric.queries.map(query => ({
      ...query,
      result: query.result.map(result => ({
        ...result,
        values: result.values.map(([timestamp, value]) => [
          new Date(timestamp * 1000).toISOString(),
          Number(value),
        ]),
      })),
    }));

    return {
      ...metric,
      queries: removeTimeSeriesNoData(queries),
    };
  });
}

export default class MonitoringStore {
  constructor() {
    this.groups = [];
    this.deploymentData = [];
    this.environmentsData = [];
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

  storeEnvironmentsData(environmentsData = []) {
    this.environmentsData = environmentsData.filter(environment => !!environment.last_deployment);
  }

  getMetricsCount() {
    return this.groups.reduce((count, group) => count + group.metrics.length, 0);
  }
}
