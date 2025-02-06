import { parseGetStorageResults } from '~/usage_quotas/storage/namespace/utils';
import { mockGetNamespaceStorageGraphQLResponse } from 'jest/usage_quotas/storage/mock_data';

describe('parseGetStorageResults', () => {
  it('returns the object keys we use', () => {
    const objectKeys = Object.keys(
      parseGetStorageResults(mockGetNamespaceStorageGraphQLResponse.data),
    );
    expect(objectKeys).toEqual([
      'additionalPurchasedStorageSize',
      'actualRepositorySizeLimit',
      'containsLockedProjects',
      'repositorySizeExcessProjectCount',
      'totalRepositorySize',
      'totalRepositorySizeExcess',
      'totalUsage',
      'rootStorageStatistics',
      'limit',
    ]);
  });
});
