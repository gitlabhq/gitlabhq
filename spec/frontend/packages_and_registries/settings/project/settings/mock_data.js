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
    minimumAccessLevelForPush: 'MAINTAINER',
  })),
  {
    id: 'gid://gitlab/Packages::Protection::Rule/16',
    packageNamePattern: '@flight/flight-owner-16-*',
    packageType: 'NPM',
    minimumAccessLevelForPush: 'OWNER',
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
  minimumAccessLevelForPush: 'MAINTAINER',
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

export const updatePackagesProtectionRuleMutationPayload = ({
  packageProtectionRule = {
    ...packagesProtectionRulesData[0],
    minimumAccessLevelForPush: 'OWNER',
  },
  errors = [],
} = {}) => ({
  data: {
    updatePackagesProtectionRule: {
      packageProtectionRule,
      errors,
    },
  },
});

export const containerProtectionRulesData = [
  ...Array.from(Array(15)).map((_e, i) => ({
    id: `gid://gitlab/ContainerRegistry::Protection::Rule/${i}`,
    repositoryPathPattern: `@flight/flight/maintainer-${i}-*`,
    minimumAccessLevelForPush: 'MAINTAINER',
    minimumAccessLevelForDelete: 'MAINTAINER',
  })),
  {
    id: 'gid://gitlab/ContainerRegistry::Protection::Rule/16',
    repositoryPathPattern: '@flight/flight/owner-16-*',
    minimumAccessLevelForPush: 'OWNER',
    minimumAccessLevelForDelete: 'OWNER',
  },
];

export const containerProtectionRuleQueryPayload = ({
  errors = [],
  nodes = containerProtectionRulesData.slice(0, 10),
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
      containerRegistryProtectionRules: {
        nodes,
        pageInfo: { __typename: 'PageInfo', ...pageInfo },
      },
      errors,
    },
  },
});

export const createContainerProtectionRuleMutationPayload = ({ override, errors = [] } = {}) => ({
  data: {
    createContainerRegistryProtectionRule: {
      containerRegistryProtectionRule: {
        ...containerProtectionRulesData[0],
        ...override,
      },
      errors,
    },
  },
});

export const createContainerProtectionRuleMutationInput = {
  repositoryPathPattern: `@flight/flight-maintainer-14-*`,
  minimumAccessLevelForPush: 'MAINTAINER',
  minimumAccessLevelForDelete: 'MAINTAINER',
};

export const createContainerProtectionRuleMutationPayloadErrors = [
  'Repository path pattern has already been taken',
];

export const deleteContainerProtectionRuleMutationPayload = ({
  containerRegistryProtectionRule = { ...containerProtectionRulesData[0] },
  errors = [],
} = {}) => ({
  data: {
    deleteContainerRegistryProtectionRule: {
      containerRegistryProtectionRule,
      errors,
    },
  },
});

export const updateContainerProtectionRuleMutationPayload = ({
  containerRegistryProtectionRule = {
    ...containerProtectionRulesData[0],
    minimumAccessLevelForPush: 'OWNER',
  },
  errors = [],
} = {}) => ({
  data: {
    updateContainerRegistryProtectionRule: {
      containerRegistryProtectionRule,
      errors,
    },
  },
});
