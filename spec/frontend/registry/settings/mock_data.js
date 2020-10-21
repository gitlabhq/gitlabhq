export const expirationPolicyPayload = override => ({
  data: {
    project: {
      containerExpirationPolicy: {
        cadence: 'EVERY_DAY',
        enabled: true,
        keepN: 'TEN_TAGS',
        nameRegex: 'asdasdssssdfdf',
        nameRegexKeep: 'sss',
        olderThan: 'FOURTEEN_DAYS',
        ...override,
      },
    },
  },
});

export const emptyExpirationPolicyPayload = () => ({
  data: {
    project: {
      containerExpirationPolicy: {},
    },
  },
});

export const expirationPolicyMutationPayload = ({ override, errors = [] } = {}) => ({
  data: {
    updateContainerExpirationPolicy: {
      containerExpirationPolicy: {
        cadence: 'EVERY_DAY',
        enabled: true,
        keepN: 'TEN_TAGS',
        nameRegex: 'asdasdssssdfdf',
        nameRegexKeep: 'sss',
        olderThan: 'FOURTEEN_DAYS',
        ...override,
      },
      errors,
    },
  },
});
