export const userCalloutsResponse = (callouts = []) => ({
  data: {
    currentUser: {
      id: 'gid://gitlab/User/46',
      __typename: 'UserCore',
      callouts: {
        __typename: 'UserCalloutConnection',
        nodes: callouts.map((callout) => ({
          __typename: 'UserCallout',
          featureName: callout.toUpperCase(),
          dismissedAt: '2021-02-12T11:10:01Z',
        })),
      },
    },
  },
});

export const anonUserCalloutsResponse = () => ({ data: { currentUser: null } });

export const userCalloutMutationResponse = (variables, errors = []) => ({
  data: {
    userCalloutCreate: {
      errors,
      userCallout: {
        featureName: variables.input.featureName.toUpperCase(),
        dismissedAt: '2021-02-12T11:10:01Z',
      },
    },
  },
});
