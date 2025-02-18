import { PROJECT_STORAGE_TYPES } from '~/usage_quotas/storage/project/constants';
import {
  getStorageTypesFromProjectStatistics,
  descendingStorageUsageSort,
} from '~/usage_quotas/storage/project/utils';
import { mockGetProjectStorageStatisticsGraphQLResponse } from 'jest/usage_quotas/storage/mock_data';

describe('getStorageTypesFromProjectStatistics', () => {
  const { statistics: projectStatistics, statisticsDetailsPaths } =
    mockGetProjectStorageStatisticsGraphQLResponse.data.project;

  describe('matches project statistics value with matching storage type', () => {
    const typesWithStats = getStorageTypesFromProjectStatistics(
      PROJECT_STORAGE_TYPES,
      projectStatistics,
    );

    it.each(PROJECT_STORAGE_TYPES)('storage type: $id', ({ id }) => {
      expect(typesWithStats).toContainEqual(
        expect.objectContaining({
          id,
          value: projectStatistics[`${id}Size`],
        }),
      );
    });
  });

  it('adds helpPath to a relevant type', () => {
    const helpLinks = PROJECT_STORAGE_TYPES.reduce((acc, { id }) => {
      return {
        ...acc,
        [id]: `url://${id}`,
      };
    }, {});

    const typesWithStats = getStorageTypesFromProjectStatistics(
      PROJECT_STORAGE_TYPES,
      projectStatistics,
      {},
      helpLinks,
    );

    typesWithStats.forEach((type) => {
      expect(type.helpPath).toBe(helpLinks[type.id]);
    });
  });

  it('adds details page path', () => {
    const typesWithStats = getStorageTypesFromProjectStatistics(
      PROJECT_STORAGE_TYPES,
      projectStatistics,
      statisticsDetailsPaths,
      {},
    );
    typesWithStats.forEach((type) => {
      expect(type.detailsPath).toBe(statisticsDetailsPaths[type.id]);
    });
  });
});

describe('descendingStorageUsageSort', () => {
  it('sorts items by a given key in descending order', () => {
    const items = [{ k: 1 }, { k: 3 }, { k: 2 }];

    const sorted = [...items].sort(descendingStorageUsageSort('k'));

    const expectedSorted = [{ k: 3 }, { k: 2 }, { k: 1 }];
    expect(sorted).toEqual(expectedSorted);
  });
});
