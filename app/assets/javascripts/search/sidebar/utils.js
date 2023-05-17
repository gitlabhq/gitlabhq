import { languageFilterData } from '~/search/sidebar/components/language_filter/data';

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
    { ...languageFilterData, filters: {} },
  );
