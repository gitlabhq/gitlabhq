export default {
  typePolicies: {
    Project: {
      fields: {
        ciCdSettings: {
          merge: true,
        },
        ciJobTokenScope: {
          merge: true,
        },
      },
    },
  },
};
