const packageDuplicateSettings = {
  mavenDuplicatesAllowed: true,
  mavenDuplicateExceptionRegex: '',
  genericDuplicatesAllowed: true,
  genericDuplicateExceptionRegex: '',
  nugetDuplicatesAllowed: true,
  nugetDuplicateExceptionRegex: '',
  terraformModuleDuplicatesAllowed: true,
  terraformModuleDuplicateExceptionRegex: '',
};

export const packageForwardingSettings = {
  mavenPackageRequestsForwarding: true,
  lockMavenPackageRequestsForwarding: false,
  npmPackageRequestsForwarding: true,
  lockNpmPackageRequestsForwarding: false,
  pypiPackageRequestsForwarding: true,
  lockPypiPackageRequestsForwarding: false,
  mavenPackageRequestsForwardingLocked: false,
  npmPackageRequestsForwardingLocked: false,
  pypiPackageRequestsForwardingLocked: false,
};

export const packageSettings = {
  ...packageDuplicateSettings,
  ...packageForwardingSettings,
};

export const dependencyProxySettings = (extend) => ({
  enabled: true,
  ...extend,
});

export const dependencyProxyImageTtlPolicy = (extend) => ({
  ttl: 90,
  enabled: true,
  ...extend,
});

export const groupPackageSettingsMock = {
  data: {
    group: {
      id: '1',
      fullPath: 'foo_group_path',
      packageSettings: {
        ...packageSettings,
        __typename: 'PackageSettings',
      },
      dependencyProxySetting: dependencyProxySettings(),
      dependencyProxyImageTtlPolicy: dependencyProxyImageTtlPolicy(),
    },
  },
};

export const npmProps = {
  forwarding: packageForwardingSettings.npmPackageRequestsForwarding,
  lockForwarding: packageForwardingSettings.lockNpmPackageRequestsForwarding,
  label: 'npm',
  disabled: false,
  modelNames: {
    forwarding: 'npmPackageRequestsForwarding',
    lockForwarding: 'lockNpmPackageRequestsForwarding',
    isLocked: 'npmPackageRequestsForwardingLocked',
  },
};

export const pypiProps = {
  forwarding: packageForwardingSettings.pypiPackageRequestsForwarding,
  lockForwarding: packageForwardingSettings.lockPypiPackageRequestsForwarding,
  label: 'PyPI',
  disabled: false,
  modelNames: {
    forwarding: 'pypiPackageRequestsForwarding',
    lockForwarding: 'lockPypiPackageRequestsForwarding',
    isLocked: 'pypiPackageRequestsForwardingLocked',
  },
};

export const mavenProps = {
  forwarding: packageForwardingSettings.mavenPackageRequestsForwarding,
  lockForwarding: packageForwardingSettings.lockMavenPackageRequestsForwarding,
  label: 'Maven',
  disabled: false,
  modelNames: {
    forwarding: 'mavenPackageRequestsForwarding',
    lockForwarding: 'lockMavenPackageRequestsForwarding',
    isLocked: 'mavenPackageRequestsForwardingLocked',
  },
};

export const groupPackageSettingsMutationMock = (override) => ({
  data: {
    updateNamespacePackageSettings: {
      packageSettings: {
        mavenDuplicatesAllowed: true,
        mavenDuplicateExceptionRegex: 'latest[main]something',
        genericDuplicatesAllowed: true,
        genericDuplicateExceptionRegex: 'latest[main]somethingGeneric',
      },
      errors: [],
      ...override,
    },
  },
});

export const groupPackageForwardSettingsMutationMock = (override) => ({
  data: {
    updateNamespacePackageSettings: {
      packageSettings: {
        npmPackageRequestsForwarding: true,
        lockNpmPackageRequestsForwarding: false,
      },
      errors: [],
      ...override,
    },
  },
});

export const dependencyProxySettingMutationMock = (override) => ({
  data: {
    updateDependencyProxySettings: {
      dependencyProxySetting: dependencyProxySettings(),
      errors: [],
      ...override,
    },
  },
});

export const dependencyProxyUpdateTllPolicyMutationMock = (override) => ({
  data: {
    updateDependencyProxyImageTtlGroupPolicy: {
      dependencyProxyImageTtlPolicy: dependencyProxyImageTtlPolicy(),
      errors: [],
      ...override,
    },
  },
});

export const groupPackageSettingsMutationErrorMock = {
  errors: [
    {
      message:
        'Variable $input of type UpdateNamespacePackageSettingsInput! was provided invalid value for mavenDuplicateExceptionRegex (latest[main]somethingj)) is an invalid regexp: unexpected ): latest[main]somethingj)))',
      locations: [{ line: 1, column: 41 }],
      extensions: {
        value: {
          namespacePath: 'gitlab-org',
          mavenDuplicateExceptionRegex: 'latest[main]something))',
        },
        problems: [
          {
            path: ['mavenDuplicateExceptionRegex'],
            explanation:
              'latest[main]somethingj)) is an invalid regexp: unexpected ): latest[main]something))',
            message:
              'latest[main]somethingj)) is an invalid regexp: unexpected ): latest[main]something))',
          },
        ],
      },
    },
  ],
};

export const mutationErrorMock = {
  errors: [
    {
      message: 'Some error',
      locations: [{ line: 1, column: 41 }],
      extensions: {
        value: {
          enabled: 'gitlab-org',
        },
        problems: [
          {
            path: ['enabled'],
            explanation: 'explaination',
            message: 'message',
          },
        ],
      },
    },
  ],
};
