export const testProjectPath = 'foo/bar';

export const textProviderIds = [101, 102];

export const securityTrainingProviders = [
  {
    id: textProviderIds[0],
    name: 'Vendor Name 1',
    description: 'Interactive developer security education',
    url: 'https://www.example.org/security/training',
    isEnabled: false,
  },
  {
    id: textProviderIds[1],
    name: 'Vendor Name 2',
    description: 'Security training with guide and learning pathways.',
    url: 'https://www.vendornametwo.com/',
    isEnabled: true,
  },
];

export const securityTrainingProvidersResponse = {
  data: {
    project: {
      id: 1,
      securityTrainingProviders,
    },
  },
};
