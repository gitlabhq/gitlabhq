import expirationPolicyQuery from '~/packages_and_registries/settings/project/graphql/queries/get_expiration_policy.query.graphql';
import { updateContainerExpirationPolicy } from '~/packages_and_registries/settings/project/graphql/utils/cache_update';

describe('Registry settings cache update', () => {
  let client;

  const payload = {
    data: {
      updateContainerExpirationPolicy: {
        containerExpirationPolicy: {
          enabled: true,
        },
      },
    },
  };

  const cacheMock = {
    project: {
      containerExpirationPolicy: {
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
      updateContainerExpirationPolicy('foo')(client, payload);
      expect(client.readQuery).toHaveBeenCalledWith(queryAndVariables);
    });

    it('writes the correct result in the cache', () => {
      updateContainerExpirationPolicy('foo')(client, payload);
      expect(client.writeQuery).toHaveBeenCalledWith({
        ...queryAndVariables,
        data: {
          project: {
            containerExpirationPolicy: {
              enabled: true,
            },
          },
        },
      });
    });
  });
});
