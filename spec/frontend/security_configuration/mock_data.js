export const securityTrainingProviders = [
  {
    id: 101,
    name: 'Kontra',
    description: 'Interactive developer security education.',
    url: 'https://application.security/',
    isEnabled: false,
  },
  {
    id: 102,
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

export const mockResolvers = {
  Query: {
    securityTrainingProviders() {
      return securityTrainingProviders;
    },
  },
};
