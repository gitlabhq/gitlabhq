import { numberToHumanSize } from '~/lib/utils/number_utils';
import { PROJECT_STORAGE_TYPES } from './constants';

export const getStorageTypesFromProjectStatistics = (
  projectStatistics,
  helpLinks = {},
  statisticsDetailsPaths = {},
) =>
  PROJECT_STORAGE_TYPES.reduce((types, currentType) => {
    const helpPath = helpLinks[currentType.id];
    const value = projectStatistics[`${currentType.id}Size`];
    const detailsPath = statisticsDetailsPaths[currentType.id];

    return types.concat({
      storageType: {
        ...currentType,
        helpPath,
        detailsPath,
      },
      value,
    });
  }, []);

/**
 * This method parses the results from `getProjectStorageStatistics` call.
 *
 * @param {Object} data graphql result
 * @returns {Object}
 */
export const parseGetProjectStorageResults = (data, helpLinks) => {
  const projectStatistics = data?.project?.statistics;
  if (!projectStatistics) {
    return {};
  }
  const { storageSize } = projectStatistics;
  const storageTypes = getStorageTypesFromProjectStatistics(
    projectStatistics,
    helpLinks,
    data?.project?.statisticsDetailsPaths,
  );

  return {
    storage: {
      totalUsage: numberToHumanSize(storageSize, 1),
      storageTypes,
    },
    statistics: projectStatistics,
  };
};

/**
 * Creates a sorting function to sort storage types by usage in the graph and in the table
 *
 * @param {string} storageUsageKey key storing value of storage usage
 * @returns {Function} sorting function
 */
export function descendingStorageUsageSort(storageUsageKey) {
  return (a, b) => b[storageUsageKey] - a[storageUsageKey];
}
