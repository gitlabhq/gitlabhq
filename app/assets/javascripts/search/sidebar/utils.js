import { languageFilterData } from '~/search/sidebar/constants/language_filter_data';

export const convertFiltersData = (rawBuckets) => {
  return rawBuckets.reduce(
    (acc, bucket) => {
      return {
        ...acc,
        filters: {
          ...acc.filters,
          [bucket.key.toUpperCase()]: {
            label: bucket.key,
            value: bucket.key,
            count: bucket.count,
          },
        },
      };
    },
    { ...languageFilterData, filters: {} },
  );
};
