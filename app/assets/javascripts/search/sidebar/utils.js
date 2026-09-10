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
          // A bucket can be selectable but still worth playing down, such as Zoekt's
          // "Unknown" language, which collects files whose language could not be detected
          // rather than describing one. Defaults to false.
          deemphasized: bucket.deemphasized === true,
        },
      },
    }),
    { filters: {} },
  );
