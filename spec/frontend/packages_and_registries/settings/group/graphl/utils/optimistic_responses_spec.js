import {
  updateGroupPackagesSettingsOptimisticResponse,
  updateGroupDependencyProxySettingsOptimisticResponse,
  updateDependencyProxyImageTtlGroupPolicyOptimisticResponse,
} from '~/packages_and_registries/settings/group/graphql/utils/optimistic_responses';

describe('Optimistic responses', () => {
  describe('updateGroupPackagesSettingsOptimisticResponse', () => {
    it('returns the correct structure', () => {
      expect(updateGroupPackagesSettingsOptimisticResponse({ foo: 'bar' })).toMatchInlineSnapshot(`
{
  "__typename": "Mutation",
  "updateNamespacePackageSettings": {
    "__typename": "UpdateNamespacePackageSettingsPayload",
    "errors": [],
    "packageSettings": {
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
{
  "__typename": "Mutation",
  "updateDependencyProxySettings": {
    "__typename": "UpdateDependencyProxySettingsPayload",
    "dependencyProxySetting": {
      "foo": "bar",
    },
    "errors": [],
  },
}
`);
    });
  });

  describe('updateDependencyProxyImageTtlGroupPolicyOptimisticResponse', () => {
    it('returns the correct structure', () => {
      expect(updateDependencyProxyImageTtlGroupPolicyOptimisticResponse({ foo: 'bar' }))
        .toMatchInlineSnapshot(`
{
  "__typename": "Mutation",
  "updateDependencyProxyImageTtlGroupPolicy": {
    "__typename": "UpdateDependencyProxyImageTtlGroupPolicyPayload",
    "dependencyProxyImageTtlPolicy": {
      "foo": "bar",
    },
    "errors": [],
  },
}
`);
    });
  });
});
