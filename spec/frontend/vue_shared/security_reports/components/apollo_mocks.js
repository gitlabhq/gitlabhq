export const buildConfigureSecurityFeatureMockFactory =
  (mutationType) =>
  ({ successPath = 'testSuccessPath', errors = [] } = {}) => ({
    data: {
      [mutationType]: {
        successPath,
        errors,
        __typename: `${mutationType}Payload`,
      },
    },
  });
