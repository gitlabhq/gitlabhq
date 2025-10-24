export const userGroupCalloutsResponse = (callouts = []) => ({
  data: {
    currentUser: {
      id: 'gid://gitlab/User/46',
      __typename: 'UserCore',
      groupCallouts: {
        __typename: 'UserGroupCalloutConnection',
        nodes: callouts.map((callout) => ({
          __typename: 'UserGroupCallout',
          featureName: callout.featureName.toUpperCase(),
          groupId: callout.groupId,
          dismissedAt: '2021-02-12T11:10:01Z',
        })),
      },
    },
  },
});

export const anonUserGroupCalloutsResponse = () => ({ data: { currentUser: null } });

export const userGroupCalloutMutationResponse = (variables, errors = []) => ({
  data: {
    userGroupCalloutCreate: {
      errors,
      userGroupCallout: {
        featureName: variables.input.featureName.toUpperCase(),
        groupId: variables.input.groupId,
        dismissedAt: '2021-02-12T11:10:01Z',
      },
    },
  },
});
