import { numberToHumanSize } from '~/lib/utils/number_utils';
import { s__ } from '~/locale';

const projectStorageTypes = [
  {
    id: 'buildArtifactsSize',
    name: s__('UsageQuota|Artifacts'),
  },
  {
    id: 'lfsObjectsSize',
    name: s__('UsageQuota|LFS Storage'),
  },
  {
    id: 'packagesSize',
    name: s__('UsageQuota|Packages'),
  },
  {
    id: 'repositorySize',
    name: s__('UsageQuota|Repository'),
  },
  {
    id: 'snippetsSize',
    name: s__('UsageQuota|Snippets'),
  },
  {
    id: 'uploadsSize',
    name: s__('UsageQuota|Uploads'),
  },
  {
    id: 'wikiSize',
    name: s__('UsageQuota|Wiki'),
  },
];

/**
 * This method parses the results from `getProjectStorageCount` call.
 *
 * @param {Object} data graphql result
 * @returns {Object}
 */
export const parseGetProjectStorageResults = (data) => {
  const projectStatistics = data?.project?.statistics;
  if (!projectStatistics) {
    return {};
  }
  const { storageSize, ...storageStatistics } = projectStatistics;
  const storageTypes = projectStorageTypes.reduce((types, currentType) => {
    if (!storageStatistics[currentType.id]) {
      return types;
    }

    return types.concat({
      ...currentType,
      value: numberToHumanSize(storageStatistics[currentType.id]),
    });
  }, []);

  return {
    storage: {
      totalUsage: numberToHumanSize(storageSize),
      storageTypes,
    },
  };
};
