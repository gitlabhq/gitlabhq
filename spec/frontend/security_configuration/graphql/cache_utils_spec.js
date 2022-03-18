import {
  updateSecurityTrainingCache,
  updateSecurityTrainingOptimisticResponse,
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
});
