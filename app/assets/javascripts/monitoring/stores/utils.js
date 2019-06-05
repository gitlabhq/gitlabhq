import _ from 'underscore';

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

// Metrics and queries are currently stored 1:1, so `queries` is an array of length one.
// We want to group queries onto a single chart by title & y-axis label.
// This function will no longer be required when metrics:queries are 1:many,
// though there is no consequence if the function stays in use.
// @param metrics [Array<Object>]
//      Ex) [
//            { id: 1, title: 'title', y_label: 'MB', queries: [{ ...query1Attrs }] },
//            { id: 2, title: 'title', y_label: 'MB', queries: [{ ...query2Attrs }] },
//            { id: 3, title: 'new title', y_label: 'MB', queries: [{ ...query3Attrs }] }
//          ]
// @return [Array<Object>]
//      Ex) [
//            { title: 'title', y_label: 'MB', queries: [{ metricId: 1, ...query1Attrs },
//                                                       { metricId: 2, ...query2Attrs }] },
//            { title: 'new title', y_label: 'MB', queries: [{ metricId: 3, ...query3Attrs }]}
//          ]
function groupQueriesByChartInfo(metrics) {
  const metricsByChart = metrics.reduce((accumulator, metric) => {
    const { queries, ...chart } = metric;
    const metricId = chart.id ? chart.id.toString() : null;

    const chartKey = `${chart.title}|${chart.y_label}`;
    accumulator[chartKey] = accumulator[chartKey] || { ...chart, queries: [] };

    queries.forEach(queryAttrs => accumulator[chartKey].queries.push({ metricId, ...queryAttrs }));

    return accumulator;
  }, {});

  return Object.values(metricsByChart);
}

export const sortMetrics = metrics =>
  _.chain(metrics)
    .sortBy('title')
    .sortBy('weight')
    .value();

export const normalizeMetrics = metrics => {
  const groupedMetrics = groupQueriesByChartInfo(metrics);

  return groupedMetrics.map(metric => {
    const queries = metric.queries.map(query => ({
      ...query,
      // custom metrics do not require a label, so we should ensure this attribute is defined
      label: query.label || metric.y_label,
      result: (query.result || []).map(timeSeries => ({
        ...timeSeries,
        values: timeSeries.values.map(([timestamp, value]) => [
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
};
