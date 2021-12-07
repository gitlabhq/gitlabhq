import {
  updateGroupPackagesSettingsOptimisticResponse,
  updateGroupDependencyProxySettingsOptimisticResponse,
  updateDependencyProxyImageTtlGroupPolicyOptimisticResponse,
} from '~/packages_and_registries/settings/group/graphql/utils/optimistic_responses';

describe('Optimistic responses', () => {
  describe('updateGroupPackagesSettingsOptimisticResponse', () => {
    it('returns the correct structure', () => {
      expect(updateGroupPackagesSettingsOptimisticResponse({ foo: 'bar' })).toMatchInlineSnapshot(`
        Object {
          "__typename": "Mutation",
          "updateNamespacePackageSettings": Object {
            "__typename": "UpdateNamespacePackageSettingsPayload",
            "errors": Array [],
            "packageSettings": Object {
              "foo": "bar",
            },
          },
        }
      `);
    });
  });

  describe('updateGroupDependencyProxySettingsOptimisticResponse', () => {
    it('returns the correct structure', () => {
      expect(updateGroupDependencyProxySettingsOptimisticResponse({ foo: 'bar' }))
        .toMatchInlineSnapshot(`
        Object {
          "__typename": "Mutation",
          "updateDependencyProxySettings": Object {
            "__typename": "UpdateDependencyProxySettingsPayload",
            "dependencyProxySetting": Object {
              "foo": "bar",
            },
            "errors": Array [],
          },
        }
      `);
    });
  });

  describe('updateDependencyProxyImageTtlGroupPolicyOptimisticResponse', () => {
    it('returns the correct structure', () => {
      expect(updateDependencyProxyImageTtlGroupPolicyOptimisticResponse({ foo: 'bar' }))
        .toMatchInlineSnapshot(`
        Object {
          "__typename": "Mutation",
          "updateDependencyProxyImageTtlGroupPolicy": Object {
            "__typename": "UpdateDependencyProxyImageTtlGroupPolicyPayload",
            "dependencyProxyImageTtlPolicy": Object {
              "foo": "bar",
            },
            "errors": Array [],
          },
        }
      `);
    });
  });
});
