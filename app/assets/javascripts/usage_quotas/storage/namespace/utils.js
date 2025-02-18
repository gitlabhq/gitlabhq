import { parseBoolean } from '~/lib/utils/common_utils';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { __ } from '~/locale';
import { storageTypeHelpPaths } from '../constants';

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

export const parseNamespaceProvideData = (el) => {
  if (!el) {
    return {};
  }

  const { namespaceId, namespacePath, userNamespace, defaultPerPage } = el.dataset;

  return {
    namespaceId: parseInt(namespaceId, 10),
    namespacePath,
    userNamespace: parseBoolean(userNamespace),
    defaultPerPage: Number(defaultPerPage),
    helpLinks: storageTypeHelpPaths,
    // only used in EE
    purchaseStorageUrl: '',
    buyAddonTargetAttr: '',
    namespacePlanName: '',
    isInNamespaceLimitsPreEnforcement: false,
    perProjectStorageLimit: false,
    namespaceStorageLimit: false,
    totalRepositorySizeExcess: false,
    isUsingProjectEnforcementWithLimits: false,
    isUsingProjectEnforcementWithNoLimits: false,
    isUsingNamespaceEnforcement: false,
    customSortKey: null,
  };
};
