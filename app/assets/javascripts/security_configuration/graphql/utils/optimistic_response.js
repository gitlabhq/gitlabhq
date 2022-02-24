export const updateSecurityTrainingOptimisticResponse = (changes) => ({
  // False positive i18n lint: https://gitlab.com/gitlab-org/frontend/eslint-plugin-i18n/issues/26
  // eslint-disable-next-line @gitlab/require-i18n-strings
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
