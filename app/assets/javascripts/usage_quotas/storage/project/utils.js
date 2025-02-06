/**
 * Parses project data injected via a DOM element
 *
 * @param {HTMLElement} el - DOM element
 * @returns parsed data
 */
export const parseProjectProvideData = (el) => {
  const { projectPath } = el.dataset;

  return {
    projectPath,
  };
};

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
  // eslint-disable-next-line max-params
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
