export const testProjectPath = 'foo/bar';

export const textProviderIds = [101, 102];

export const securityTrainingProviders = [
  {
    id: textProviderIds[0],
    name: 'Kontra',
    description: 'Interactive developer security education.',
    url: 'https://application.security/',
    isEnabled: false,
  },
  {
    id: textProviderIds[1],
    name: 'SecureCodeWarrior',
    description: 'Security training with guide and learning pathways.',
    url: 'https://www.securecodewarrior.com/',
    isEnabled: true,
  },
];

export const securityTrainingProvidersResponse = {
  data: {
    securityTrainingProviders,
  },
};

const defaultMockResolvers = {
  Query: {
    securityTrainingProviders() {
      return securityTrainingProviders;
    },
  },
};

export const createMockResolvers = ({ resolvers: customMockResolvers = {} } = {}) => ({
  ...defaultMockResolvers,
  ...customMockResolvers,
});
