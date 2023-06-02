import cloneDeep from 'lodash/cloneDeep';
import { PROJECT_STORAGE_TYPES } from '~/usage_quotas/storage/constants';
import {
  parseGetProjectStorageResults,
  getStorageTypesFromProjectStatistics,
  descendingStorageUsageSort,
} from '~/usage_quotas/storage/utils';
import {
  mockGetProjectStorageStatisticsGraphQLResponse,
  defaultProjectProvideValues,
  projectData,
} from './mock_data';

describe('getStorageTypesFromProjectStatistics', () => {
  const {
    statistics: projectStatistics,
    statisticsDetailsPaths,
  } = mockGetProjectStorageStatisticsGraphQLResponse.data.project;

  describe('matches project statistics value with matching storage type', () => {
    const typesWithStats = getStorageTypesFromProjectStatistics(projectStatistics);

    it.each(PROJECT_STORAGE_TYPES)('storage type: $id', ({ id }) => {
      expect(typesWithStats).toContainEqual({
        storageType: expect.objectContaining({
          id,
        }),
        value: projectStatistics[`${id}Size`],
      });
    });
  });

  it('adds helpPath to a relevant type', () => {
    const helpLinks = PROJECT_STORAGE_TYPES.reduce((acc, { id }) => {
      return {
        ...acc,
        [id]: `url://${id}`,
      };
    }, {});

    const typesWithStats = getStorageTypesFromProjectStatistics(projectStatistics, helpLinks);

    typesWithStats.forEach((type) => {
      const key = type.storageType.id;
      expect(type.storageType.helpPath).toBe(helpLinks[key]);
    });
  });

  it('adds details page path', () => {
    const typesWithStats = getStorageTypesFromProjectStatistics(
      projectStatistics,
      {},
      statisticsDetailsPaths,
    );
    typesWithStats.forEach((type) => {
      expect(type.storageType.detailsPath).toBe(statisticsDetailsPaths[type.storageType.id]);
    });
  });
});

describe('parseGetProjectStorageResults', () => {
  it('parses project statistics correctly', () => {
    expect(
      parseGetProjectStorageResults(
        mockGetProjectStorageStatisticsGraphQLResponse.data,
        defaultProjectProvideValues.helpLinks,
      ),
    ).toMatchObject(projectData);
  });

  it('includes storage type with size of 0 in returned value', () => {
    const mockedResponse = cloneDeep(mockGetProjectStorageStatisticsGraphQLResponse.data);
    // ensuring a specific storage type item has size of 0
    mockedResponse.project.statistics.repositorySize = 0;

    const response = parseGetProjectStorageResults(
      mockedResponse,
      defaultProjectProvideValues.helpLinks,
    );

    expect(response.storage.storageTypes).toEqual(
      expect.arrayContaining([
        {
          storageType: expect.any(Object),
          value: 0,
        },
      ]),
    );
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
