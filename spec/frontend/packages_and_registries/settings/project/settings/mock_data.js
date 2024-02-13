export const containerExpirationPolicyData = () => ({
  __typename: 'ContainerExpirationPolicy',
  cadence: 'EVERY_DAY',
  enabled: true,
  keepN: 'TEN_TAGS',
  nameRegex: 'asdasdssssdfdf',
  nameRegexKeep: 'sss',
  olderThan: 'FOURTEEN_DAYS',
  nextRunAt: '2020-11-19T07:37:03.941Z',
});

export const expirationPolicyPayload = (override) => ({
  data: {
    project: {
      id: '1',
      containerExpirationPolicy: {
        ...containerExpirationPolicyData(),
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

export const nullExpirationPolicyPayload = () => ({
  data: {
    project: {
      id: '1',
      containerExpirationPolicy: null,
    },
  },
});

export const expirationPolicyMutationPayload = ({ override, errors = [] } = {}) => ({
  data: {
    updateContainerExpirationPolicy: {
      containerExpirationPolicy: {
        ...containerExpirationPolicyData(),
        ...override,
      },
      errors,
    },
  },
});

export const packagesCleanupPolicyData = {
  __typename: 'PackagesCleanupPolicy',
  keepNDuplicatedPackageFiles: 'ALL_PACKAGE_FILES',
  nextRunAt: '2020-11-19T07:37:03.941Z',
};

export const packagesCleanupPolicyPayload = (override) => ({
  data: {
    project: {
      id: '1',
      packagesCleanupPolicy: {
        ...packagesCleanupPolicyData,
        ...override,
      },
    },
  },
});

export const packagesCleanupPolicyMutationPayload = ({ override, errors = [] } = {}) => ({
  data: {
    updatePackagesCleanupPolicy: {
      packagesCleanupPolicy: {
        ...packagesCleanupPolicyData,
        ...override,
      },
      errors,
    },
  },
});

export const packagesProtectionRulesData = [
  ...Array.from(Array(15)).map((_e, i) => ({
    id: `gid://gitlab/Packages::Protection::Rule/${i}`,
    packageNamePattern: `@flight/flight-maintainer-${i}-*`,
    packageType: 'NPM',
    pushProtectedUpToAccessLevel: 'MAINTAINER',
  })),
  {
    id: 'gid://gitlab/Packages::Protection::Rule/16',
    packageNamePattern: '@flight/flight-owner-16-*',
    packageType: 'NPM',
    pushProtectedUpToAccessLevel: 'OWNER',
  },
];

export const packagesProtectionRuleQueryPayload = ({
  errors = [],
  nodes = packagesProtectionRulesData.slice(0, 10),
  pageInfo = {
    hasNextPage: true,
    hasPreviousPage: false,
    startCursor: '0',
    endCursor: '10',
  },
} = {}) => ({
  data: {
    project: {
      id: '1',
      packagesProtectionRules: {
        nodes,
        pageInfo: { __typename: 'PageInfo', ...pageInfo },
      },
      errors,
    },
  },
});

export const createPackagesProtectionRuleMutationPayload = ({ override, errors = [] } = {}) => ({
  data: {
    createPackagesProtectionRule: {
      packageProtectionRule: {
        ...packagesProtectionRulesData[0],
        ...override,
      },
      errors,
    },
  },
});

export const createPackagesProtectionRuleMutationInput = {
  packageNamePattern: `@flight/flight-developer-14-*`,
  packageType: 'NPM',
  pushProtectedUpToAccessLevel: 'DEVELOPER',
};

export const createPackagesProtectionRuleMutationPayloadErrors = [
  'Package name pattern has already been taken',
];

export const deletePackagesProtectionRuleMutationPayload = ({
  packageProtectionRule = { ...packagesProtectionRulesData[0] },
  errors = [],
} = {}) => ({
  data: {
    deletePackagesProtectionRule: {
      packageProtectionRule,
      errors,
    },
  },
});
