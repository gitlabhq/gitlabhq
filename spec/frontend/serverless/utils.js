export const adjustMetricQuery = (data) => {
  const updatedMetric = data.metrics;

  const queries = data.metrics.queries.map((query) => ({
    ...query,
    result: query.result.map((result) => ({
      ...result,
      values: result.values.map(([timestamp, value]) => ({
        time: new Date(timestamp * 1000).toISOString(),
        value: Number(value),
      })),
    })),
  }));

  updatedMetric.queries = queries;
  return updatedMetric;
};
