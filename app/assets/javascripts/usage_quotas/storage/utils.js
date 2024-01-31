import { numberToHumanSize } from '~/lib/utils/number_utils';
import { __ } from '~/locale';

/**
 * Populates an array of storage types with usage value and other details
 *
 * @param {Array} selectedStorageTypes selected storage types that will be populated
 * @param {Object} projectStatistics object of storage values, with storage type as keys
 * @param {Object} statisticsDetailsPaths object of storage detail paths, with storage type as keys
 * @param {Object} helpLinks object of help paths, with storage type as keys
 * @returns {Array}
 */
export const getStorageTypesFromProjectStatistics = (
  selectedStorageTypes,
  projectStatistics,
  statisticsDetailsPaths = {},
  helpLinks = {},
) =>
  selectedStorageTypes.reduce((types, currentType) => {
    const helpPath = helpLinks[currentType.id];
    const value = projectStatistics[`${currentType.id}Size`];
    const detailsPath = statisticsDetailsPaths[currentType.id];

    return types.concat({
      ...currentType,
      helpPath,
      detailsPath,
      value,
    });
  }, []);

/**
 * Creates a sorting function to sort storage types by usage in the graph and in the table
 *
 * @param {string} storageUsageKey key storing value of storage usage
 * @returns {Function} sorting function
 */
export function descendingStorageUsageSort(storageUsageKey) {
  return (a, b) => b[storageUsageKey] - a[storageUsageKey];
}

/**
 * This method parses the results from `getNamespaceStorageStatistics`
 * call.
 *
 * `rootStorageStatistics` will be sent as null until an
 * event happens to trigger the storage count.
 * For that reason we have to verify if `storageSize` is sent or
 * if we should render 'Not applicable.'
 *
 * @param {Object} data graphql result
 * @returns {Object}
 */
export const parseGetStorageResults = (data) => {
  const {
    namespace: {
      storageSizeLimit,
      totalRepositorySize,
      containsLockedProjects,
      totalRepositorySizeExcess,
      rootStorageStatistics = {},
      actualRepositorySizeLimit,
      additionalPurchasedStorageSize,
      repositorySizeExcessProjectCount,
    },
  } = data || {};

  const totalUsage = rootStorageStatistics?.storageSize
    ? numberToHumanSize(rootStorageStatistics.storageSize)
    : __('Not applicable.');

  return {
    additionalPurchasedStorageSize,
    actualRepositorySizeLimit,
    containsLockedProjects,
    repositorySizeExcessProjectCount,
    totalRepositorySize,
    totalRepositorySizeExcess,
    totalUsage,
    rootStorageStatistics,
    limit: storageSizeLimit,
  };
};
