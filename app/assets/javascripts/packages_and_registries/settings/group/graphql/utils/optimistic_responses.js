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
