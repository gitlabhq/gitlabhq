export const convertFiltersData = (rawBuckets) =>
  rawBuckets.reduce(
    (acc, bucket) => ({
      ...acc,
      filters: {
        ...acc.filters,
        [bucket.key.toUpperCase()]: {
          label: bucket.key,
          value: bucket.key,
          count: bucket.count,
        },
      },
    }),
    { filters: {} },
  );
