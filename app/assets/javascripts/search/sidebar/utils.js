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
          // Buckets flagged as non-filterable (e.g. Zoekt's synthetic "Unknown" language bucket,
          // which the backend cannot express as a `lang:` atom) render as a count-only row without
          // a checkbox. Defaults to true when the backend omits the flag.
          filterable: bucket.filterable !== false,
        },
      },
    }),
    { filters: {} },
  );
