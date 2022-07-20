export const testProjectPath = 'foo/bar';
export const testProviderIds = [101, 102, 103];
export const testProviderName = ['Kontra', 'Secure Code Warrior', 'Other Vendor'];
export const testTrainingUrls = [
  'https://www.vendornameone.com/url',
  'https://www.vendornametwo.com/url',
];

const createSecurityTrainingProviders = ({ providerOverrides = {} }) => [
  {
    id: testProviderIds[0],
    name: testProviderName[0],
    description: 'Interactive developer security education',
    url: 'https://www.example.org/security/training',
    isEnabled: false,
    isPrimary: false,
    ...providerOverrides.first,
  },
  {
    id: testProviderIds[1],
    name: testProviderName[1],
    description: 'Security training with guide and learning pathways.',
    url: 'https://www.vendornametwo.com/',
    isEnabled: false,
    isPrimary: false,
    ...providerOverrides.second,
  },
  {
    id: testProviderIds[2],
    name: testProviderName[2],
    description: 'Security training for the everyday developer.',
    url: 'https://www.vendornamethree.com/',
    isEnabled: false,
    isPrimary: false,
    ...providerOverrides.third,
  },
];

export const getSecurityTrainingProvidersData = (providerOverrides = {}) => {
  const securityTrainingProviders = createSecurityTrainingProviders(providerOverrides);
  const response = {
    data: {
      project: {
        id: 'gid://gitlab/Project/1',
        __typename: 'Project',
        securityTrainingProviders,
      },
    },
  };

  return {
    response,
    data: securityTrainingProviders,
  };
};

export const dismissUserCalloutResponse = {
  data: {
    userCalloutCreate: {
      errors: [],
      userCallout: {
        dismissedAt: '2022-02-02T04:36:57Z',
        featureName: 'SECURITY_TRAINING_FEATURE_PROMOTION',
      },
    },
  },
};

export const dismissUserCalloutErrorResponse = {
  data: {
    userCalloutCreate: {
      errors: ['Something went wrong'],
      userCallout: {
        dismissedAt: '',
        featureName: 'SECURITY_TRAINING_FEATURE_PROMOTION',
      },
    },
  },
};

export const updateSecurityTrainingProvidersResponse = {
  data: {
    securityTrainingUpdate: {
      errors: [],
      training: {
        id: 101,
        name: 'Acme',
        isEnabled: true,
        isPrimary: false,
      },
    },
  },
};

export const updateSecurityTrainingProvidersErrorResponse = {
  data: {
    securityTrainingUpdate: {
      errors: ['something went wrong!'],
      training: null,
    },
  },
};
