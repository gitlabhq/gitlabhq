import expirationPolicyQuery from '~/packages_and_registries/settings/group/graphql/queries/get_group_packages_settings.query.graphql';
import { updateGroupPackageSettings } from '~/packages_and_registries/settings/group/graphql/utils/cache_update';

describe('Package and Registries settings group cache updates', () => {
  let client;

  const updateNamespacePackageSettingsPayload = {
    packageSettings: {
      mavenDuplicatesAllowed: false,
      mavenDuplicateExceptionRegex: 'latest[main]something',
    },
  };

  const updateDependencyProxySettingsPayload = {
    dependencyProxySetting: {
      enabled: false,
    },
  };

  const cacheMock = {
    group: {
      packageSettings: {
        mavenDuplicatesAllowed: true,
        mavenDuplicateExceptionRegex: '',
      },
      dependencyProxySetting: {
        enabled: true,
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

  describe.each`
    updateNamespacePackageSettings           | updateDependencyProxySettings
    ${updateNamespacePackageSettingsPayload} | ${updateDependencyProxySettingsPayload}
    ${undefined}                             | ${updateDependencyProxySettingsPayload}
    ${updateNamespacePackageSettingsPayload} | ${undefined}
    ${undefined}                             | ${undefined}
  `(
    'updateGroupPackageSettings',
    ({ updateNamespacePackageSettings, updateDependencyProxySettings }) => {
      const payload = { data: { updateNamespacePackageSettings, updateDependencyProxySettings } };
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
              ...cacheMock.group,
              ...payload.data.updateNamespacePackageSettings,
              ...payload.data.updateDependencyProxySettings,
            },
          },
        });
      });
    },
  );
});
