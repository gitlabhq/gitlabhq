import expirationPolicyQuery from '~/packages_and_registries/settings/group/graphql/queries/get_group_packages_settings.query.graphql';
import { updateGroupPackageSettings } from '~/packages_and_registries/settings/group/graphql/utils/cache_update';

describe('Package and Registries settings group cache updates', () => {
  let client;

  const payload = {
    data: {
      updateNamespacePackageSettings: {
        packageSettings: {
          mavenDuplicatesAllowed: false,
          mavenDuplicateExceptionRegex: 'latest[main]something',
        },
      },
    },
  };

  const cacheMock = {
    group: {
      packageSettings: {
        mavenDuplicatesAllowed: true,
        mavenDuplicateExceptionRegex: '',
      },
    },
  };

  const queryAndVariables = {
    query: expirationPolicyQuery,
    variables: { fullPath: 'foo' },
  };

  beforeEach(() => {
    client = {
      readQuery: jest.fn().mockReturnValue(cacheMock),
      writeQuery: jest.fn(),
    };
  });
  describe('updateGroupPackageSettings', () => {
    it('calls readQuery', () => {
      updateGroupPackageSettings('foo')(client, payload);
      expect(client.readQuery).toHaveBeenCalledWith(queryAndVariables);
    });

    it('writes the correct result in the cache', () => {
      updateGroupPackageSettings('foo')(client, payload);
      expect(client.writeQuery).toHaveBeenCalledWith({
        ...queryAndVariables,
        data: {
          group: {
            ...payload.data.updateNamespacePackageSettings,
          },
        },
      });
    });
  });
});
