import cacheConfig from '~/ci/admin/jobs_table/graphql/cache_config';
import {
  CIJobConnectionExistingCache,
  CIJobConnectionIncomingCache,
  CIJobConnectionIncomingCacheRunningStatus,
} from 'jest/ci/jobs_mock_data';

const firstLoadArgs = { first: 3, statuses: 'PENDING' };
const runningArgs = { first: 3, statuses: 'RUNNING' };

describe('jobs/components/table/graphql/cache_config', () => {
  describe('when fetching data with the same statuses', () => {
    it('should contain cache nodes and a status when merging caches on first load', () => {
      const res = cacheConfig.typePolicies.CiJobConnection.merge({}, CIJobConnectionIncomingCache, {
        args: firstLoadArgs,
      });

      expect(res.nodes).toHaveLength(CIJobConnectionIncomingCache.nodes.length);
      expect(res.statuses).toBe('PENDING');
    });

    it('should add to existing caches when merging caches after first load', () => {
      const res = cacheConfig.typePolicies.CiJobConnection.merge(
        CIJobConnectionExistingCache,
        CIJobConnectionIncomingCache,
        {
          args: firstLoadArgs,
        },
      );

      expect(res.nodes).toHaveLength(
        CIJobConnectionIncomingCache.nodes.length + CIJobConnectionExistingCache.nodes.length,
      );
    });

    it('should not add to existing cache if the incoming elements are the same', () => {
      // simulate that this is the last page
      const finalExistingCache = {
        ...CIJobConnectionExistingCache,
        pageInfo: {
          hasNextPage: false,
        },
      };

      const res = cacheConfig.typePolicies.CiJobConnection.merge(
        CIJobConnectionExistingCache,
        finalExistingCache,
        {
          args: firstLoadArgs,
        },
      );

      expect(res.nodes).toHaveLength(CIJobConnectionExistingCache.nodes.length);
    });

    it('should contain the pageInfo key as part of the result', () => {
      const res = cacheConfig.typePolicies.CiJobConnection.merge({}, CIJobConnectionIncomingCache, {
        args: firstLoadArgs,
      });

      expect(res.pageInfo).toEqual(
        expect.objectContaining({
          __typename: 'PageInfo',
          endCursor: 'eyJpZCI6IjIwNTEifQ',
          hasNextPage: true,
          hasPreviousPage: false,
          startCursor: 'eyJpZCI6IjIxNzMifQ',
        }),
      );
    });
  });

  describe('when fetching data with different statuses', () => {
    it('should reset cache when a cache already exists', () => {
      const res = cacheConfig.typePolicies.CiJobConnection.merge(
        CIJobConnectionExistingCache,
        CIJobConnectionIncomingCacheRunningStatus,
        {
          args: runningArgs,
        },
      );

      expect(res.nodes).not.toEqual(CIJobConnectionExistingCache.nodes);
      expect(res.nodes).toHaveLength(CIJobConnectionIncomingCacheRunningStatus.nodes.length);
    });
  });

  describe('when incoming data has no nodes', () => {
    it('should return existing cache', () => {
      const res = cacheConfig.typePolicies.CiJobConnection.merge(
        CIJobConnectionExistingCache,
        { __typename: 'CiJobConnection', count: 500 },
        {
          args: { statuses: 'SUCCESS' },
        },
      );

      const expectedResponse = {
        ...CIJobConnectionExistingCache,
        statuses: 'SUCCESS',
      };

      expect(res).toEqual(expectedResponse);
    });
  });
});
