import expirationPolicyQuery from '~/packages_and_registries/settings/project/graphql/queries/get_expiration_policy.query.graphql';
import { updateContainerExpirationPolicy } from '~/packages_and_registries/settings/project/graphql/utils/cache_update';

describe('Registry settings cache update', () => {
  let client;

  const payload = (value) => ({
    data: {
      updateContainerExpirationPolicy: {
        containerTagsExpirationPolicy: {
          ...value,
        },
      },
    },
  });

  const cacheMock = {
    project: {
      containerTagsExpirationPolicy: {
        enabled: false,
      },
    },
  };

  const queryAndVariables = {
    query: expirationPolicyQuery,
    variables: { projectPath: 'foo' },
  };

  beforeEach(() => {
    client = {
      readQuery: jest.fn().mockReturnValue(cacheMock),
      writeQuery: jest.fn(),
    };
  });
  describe('Registry settings cache update', () => {
    it('calls readQuery', () => {
      updateContainerExpirationPolicy('foo')(client, payload({ enabled: true }));
      expect(client.readQuery).toHaveBeenCalledWith(queryAndVariables);
    });

    it('writes the correct result in the cache', () => {
      updateContainerExpirationPolicy('foo')(client, payload({ enabled: true }));
      expect(client.writeQuery).toHaveBeenCalledWith({
        ...queryAndVariables,
        data: {
          project: {
            containerTagsExpirationPolicy: {
              enabled: true,
            },
          },
        },
      });
    });

    it('with an empty update preserves the state', () => {
      updateContainerExpirationPolicy('foo')(client, payload());

      expect(client.writeQuery).toHaveBeenCalledWith({
        ...queryAndVariables,
        data: {
          project: {
            containerTagsExpirationPolicy: {
              enabled: false,
            },
          },
        },
      });
    });
  });
});
