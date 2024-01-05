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
  {
    id: `gid://gitlab/Packages::Protection::Rule/14`,
    packageNamePattern: `@flight/flight-maintainer-14-*`,
    packageType: 'NPM',
    pushProtectedUpToAccessLevel: 'MAINTAINER',
  },
  {
    id: `gid://gitlab/Packages::Protection::Rule/15`,
    packageNamePattern: `@flight/flight-maintainer-15-*`,
    packageType: 'NPM',
    pushProtectedUpToAccessLevel: 'MAINTAINER',
  },
  {
    id: 'gid://gitlab/Packages::Protection::Rule/16',
    packageNamePattern: '@flight/flight-owner-16-*',
    packageType: 'NPM',
    pushProtectedUpToAccessLevel: 'OWNER',
  },
];

export const packagesProtectionRuleQueryPayload = ({ override, errors = [] } = {}) => ({
  data: {
    project: {
      id: '1',
      packagesProtectionRules: {
        nodes: override || packagesProtectionRulesData,
      },
      errors,
    },
  },
});
