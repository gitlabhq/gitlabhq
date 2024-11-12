export const updateGroupPackagesSettingsOptimisticResponse = (changes) => ({
  __typename: 'Mutation',
  updateNamespacePackageSettings: {
    __typename: 'UpdateNamespacePackageSettingsPayload',
    errors: [],
    packageSettings: {
      ...changes,
    },
  },
});

export const updateGroupDependencyProxySettingsOptimisticResponse = (changes) => ({
  __typename: 'Mutation',
  updateDependencyProxySettings: {
    __typename: 'UpdateDependencyProxySettingsPayload',
    errors: [],
    dependencyProxySetting: {
      ...changes,
    },
  },
});

export const updateDependencyProxyImageTtlGroupPolicyOptimisticResponse = (changes) => ({
  __typename: 'Mutation',
  updateDependencyProxyImageTtlGroupPolicy: {
    __typename: 'UpdateDependencyProxyImageTtlGroupPolicyPayload',
    errors: [],
    dependencyProxyImageTtlPolicy: {
      ...changes,
    },
  },
});
