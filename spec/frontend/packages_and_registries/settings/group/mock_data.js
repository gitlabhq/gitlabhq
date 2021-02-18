export const groupPackageSettingsMock = {
  data: {
    group: {
      packageSettings: {
        mavenDuplicatesAllowed: true,
        mavenDuplicateExceptionRegex: '',
      },
    },
  },
};

export const groupPackageSettingsMutationMock = (override) => ({
  data: {
    updateNamespacePackageSettings: {
      packageSettings: {
        mavenDuplicatesAllowed: true,
        mavenDuplicateExceptionRegex: 'latest[master]something',
      },
      errors: [],
      ...override,
    },
  },
});

export const groupPackageSettingsMutationErrorMock = {
  errors: [
    {
      message:
        'Variable $input of type UpdateNamespacePackageSettingsInput! was provided invalid value for mavenDuplicateExceptionRegex (latest[master]somethingj)) is an invalid regexp: unexpected ): latest[master]somethingj)))',
      locations: [{ line: 1, column: 41 }],
      extensions: {
        value: {
          namespacePath: 'gitlab-org',
          mavenDuplicateExceptionRegex: 'latest[master]something))',
        },
        problems: [
          {
            path: ['mavenDuplicateExceptionRegex'],
            explanation:
              'latest[master]somethingj)) is an invalid regexp: unexpected ): latest[master]something))',
            message:
              'latest[master]somethingj)) is an invalid regexp: unexpected ): latest[master]something))',
          },
        ],
      },
    },
  ],
};
