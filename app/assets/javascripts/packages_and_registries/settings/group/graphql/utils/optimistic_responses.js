export const updateGroupPackagesSettingsOptimisticResponse = (changes) => ({
  // eslint-disable-next-line @gitlab/require-i18n-strings
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
  // eslint-disable-next-line @gitlab/require-i18n-strings
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
  // eslint-disable-next-line @gitlab/require-i18n-strings
  __typename: 'Mutation',
  updateDependencyProxyImageTtlGroupPolicy: {
    __typename: 'UpdateDependencyProxyImageTtlGroupPolicyPayload',
    errors: [],
    dependencyProxyImageTtlPolicy: {
      ...changes,
    },
  },
});
