export const containerTagsExpirationPolicyData = () => ({
  __typename: 'ContainerTagsExpirationPolicy',
  cadence: 'EVERY_DAY',
  enabled: true,
  keepN: 'TEN_TAGS',
  nameRegex: 'asdasdssssdfdf',
  nameRegexKeep: 'sss',
  olderThan: 'FOURTEEN_DAYS',
  nextRunAt: '2020-11-19T07:37:03.941Z',
});

export const expirationPolicyEnabledPayload = {
  data: {
    project: {
      id: '1',
      containerTagsExpirationPolicy: {
        enabled: containerTagsExpirationPolicyData().enabled,
        nextRunAt: containerTagsExpirationPolicyData().nextRunAt,
        __typename: 'ContainerTagsExpirationPolicy',
      },
    },
  },
};

export const expirationPolicyPayload = (override) => ({
  data: {
    project: {
      id: '1',
      containerTagsExpirationPolicy: {
        ...containerTagsExpirationPolicyData(),
        ...override,
      },
    },
  },
});

export const emptyExpirationPolicyPayload = () => ({
  data: {
    project: {
      containerTagsExpirationPolicy: {},
    },
  },
});

export const nullExpirationPolicyPayload = () => ({
  data: {
    project: {
      id: '1',
      containerTagsExpirationPolicy: null,
    },
  },
});

export const expirationPolicyMutationPayload = ({ override, errors = [] } = {}) => ({
  data: {
    updateContainerExpirationPolicy: {
      containerTagsExpirationPolicy: {
        ...containerTagsExpirationPolicyData(),
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

export const containerProtectionRepositoryRulesData = [
  ...Array.from(Array(15)).map((_e, i) => ({
    id: `gid://gitlab/ContainerRegistry::Protection::Rule/${i}`,
    repositoryPathPattern: `@flight/flight/maintainer-${i}-*`,
    minimumAccessLevelForPush: 'MAINTAINER',
  })),
  {
    id: 'gid://gitlab/ContainerRegistry::Protection::Rule/16',
    repositoryPathPattern: '@flight/flight/owner-16-*',
    minimumAccessLevelForPush: 'OWNER',
  },
];

export const containerProtectionRepositoryRuleQueryPayload = ({
  errors = [],
  nodes = containerProtectionRepositoryRulesData.slice(0, 10),
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
      containerProtectionRepositoryRules: {
        nodes,
        pageInfo: { __typename: 'PageInfo', ...pageInfo },
      },
      errors,
    },
  },
});

export const createContainerProtectionRepositoryRuleMutationPayload = ({
  override,
  errors = [],
} = {}) => ({
  data: {
    createContainerProtectionRepositoryRule: {
      containerProtectionRepositoryRule: {
        ...containerProtectionRepositoryRulesData[0],
        ...override,
      },
      errors,
    },
  },
});

export const createContainerProtectionRepositoryRuleMutationInput = {
  repositoryPathPattern: `@flight/flight-maintainer-14-*`,
  minimumAccessLevelForPush: 'MAINTAINER',
};

export const createContainerProtectionRepositoryRuleMutationPayloadErrors = [
  'Repository path pattern should be a valid container repository path with optional wildcard characters.',
  "Repository path pattern should start with the project's full path",
];

export const deleteContainerProtectionRepositoryRuleMutationPayload = ({
  containerProtectionRepositoryRule = { ...containerProtectionRepositoryRulesData[0] },
  errors = [],
} = {}) => ({
  data: {
    deleteContainerProtectionRepositoryRule: {
      containerProtectionRepositoryRule,
      errors,
    },
  },
});

export const updateContainerProtectionRepositoryRuleMutationPayload = ({
  containerProtectionRepositoryRule = {
    ...containerProtectionRepositoryRulesData[0],
    minimumAccessLevelForPush: 'OWNER',
  },
  errors = [],
} = {}) => ({
  data: {
    updateContainerProtectionRepositoryRule: {
      containerProtectionRepositoryRule,
      errors,
    },
  },
});

export const containerProtectionTagRuleMutationInput = {
  tagNamePattern: 'v.+',
  minimumAccessLevelForPush: 'MAINTAINER',
  minimumAccessLevelForDelete: 'MAINTAINER',
};
