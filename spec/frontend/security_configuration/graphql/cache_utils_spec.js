import {
  updateSecurityTrainingCache,
  updateSecurityTrainingOptimisticResponse,
  untrackRefsOptimisticResponse,
  updateUntrackedRefsCache,
} from '~/security_configuration/graphql/cache_utils';

describe('EE - Security configuration graphQL cache utils', () => {
  describe('updateSecurityTrainingOptimisticResponse', () => {
    it('returns an optimistic response in the correct shape', () => {
      const changes = { isEnabled: true, isPrimary: true };
      const mutationResponse = updateSecurityTrainingOptimisticResponse(changes);

      expect(mutationResponse).toEqual({
        __typename: 'Mutation',
        securityTrainingUpdate: {
          __typename: 'SecurityTrainingUpdatePayload',
          training: {
            __typename: 'ProjectSecurityTraining',
            ...changes,
          },
          errors: [],
        },
      });
    });
  });

  describe('updateSecurityTrainingCache', () => {
    let mockCache;

    beforeEach(() => {
      // freezing the data makes sure that we don't mutate the original project
      const mockCacheData = Object.freeze({
        project: {
          securityTrainingProviders: [
            { id: 1, isEnabled: true, isPrimary: true },
            { id: 2, isEnabled: true, isPrimary: false },
            { id: 3, isEnabled: false, isPrimary: false },
          ],
        },
      });

      mockCache = {
        readQuery: () => mockCacheData,
        writeQuery: jest.fn(),
      };
    });

    it('does not update the cache when the primary provider is not getting disabled', () => {
      const providerAfterUpdate = {
        id: 2,
        isEnabled: true,
        isPrimary: false,
      };

      updateSecurityTrainingCache({
        query: 'GraphQL query',
        variables: { fullPath: 'gitlab/project' },
      })(mockCache, {
        data: {
          securityTrainingUpdate: {
            training: {
              ...providerAfterUpdate,
            },
          },
        },
      });

      expect(mockCache.writeQuery).not.toHaveBeenCalled();
    });

    it('sets the previous primary provider to be non-primary when another provider gets set as primary', () => {
      const providerAfterUpdate = {
        id: 2,
        isEnabled: true,
        isPrimary: true,
      };

      const expectedTrainingProvidersWrittenToCache = [
        // this was the previous primary primary provider and it should not be primary any longer
        { id: 1, isEnabled: true, isPrimary: false },
        { id: 2, isEnabled: true, isPrimary: true },
        { id: 3, isEnabled: false, isPrimary: false },
      ];

      updateSecurityTrainingCache({
        query: 'GraphQL query',
        variables: { fullPath: 'gitlab/project' },
      })(mockCache, {
        data: {
          securityTrainingUpdate: {
            training: {
              ...providerAfterUpdate,
            },
          },
        },
      });

      expect(mockCache.writeQuery).toHaveBeenCalledWith(
        expect.objectContaining({
          data: {
            project: {
              securityTrainingProviders: expectedTrainingProvidersWrittenToCache,
            },
          },
        }),
      );
    });
  });

  describe('untrackRefsOptimisticResponse', () => {
    it('returns an optimistic response in the correct shape with provided refIds', () => {
      const refIds = ['gid://gitlab/TrackedRef/1', 'gid://gitlab/TrackedRef/2'];
      const mutationResponse = untrackRefsOptimisticResponse(refIds);

      expect(mutationResponse).toEqual({
        __typename: 'Mutation',
        securityTrackedRefsUntrack: {
          __typename: 'SecurityTrackedRefsUntrackPayload',
          errors: [],
          untrackedRefIds: refIds,
        },
      });
    });
  });

  describe('updateUntrackedRefsCache', () => {
    let mockCache;

    beforeEach(() => {
      const mockCacheData = {
        project: {
          id: 'gid://gitlab/Project/1',
          __typename: 'Project',
          securityTrackedRefs: [
            { id: 'gid://gitlab/TrackedRef/1', name: 'main' },
            { id: 'gid://gitlab/TrackedRef/2', name: 'develop' },
            { id: 'gid://gitlab/TrackedRef/3', name: 'feature' },
          ],
        },
      };

      mockCache = {
        updateQuery: jest.fn((options, updateFn) => {
          const result = updateFn(mockCacheData);
          return result;
        }),
      };
    });

    it('removes untracked refs from the cache', () => {
      const untrackedRefIds = ['gid://gitlab/TrackedRef/1', 'gid://gitlab/TrackedRef/2'];

      updateUntrackedRefsCache({
        query: 'GraphQL query',
        variables: { fullPath: 'gitlab/project' },
      })(mockCache, {
        data: {
          securityTrackedRefsUntrack: {
            untrackedRefIds,
          },
        },
      });

      expect(mockCache.updateQuery).toHaveBeenCalled();
      const updateFn = mockCache.updateQuery.mock.calls[0][1];
      const result = updateFn({
        project: {
          id: 'gid://gitlab/Project/1',
          __typename: 'Project',
          securityTrackedRefs: [
            { id: 'gid://gitlab/TrackedRef/1', name: 'main' },
            { id: 'gid://gitlab/TrackedRef/2', name: 'develop' },
            { id: 'gid://gitlab/TrackedRef/3', name: 'feature' },
          ],
        },
      });

      untrackedRefIds.forEach((refId) => {
        expect(result.project.securityTrackedRefs.some((ref) => ref.id === refId)).toBe(false);
      });
    });
  });
});
