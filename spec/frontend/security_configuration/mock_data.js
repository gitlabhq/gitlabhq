import {
  SAST_NAME,
  SAST_SHORT_NAME,
  SAST_IAC_NAME,
  SAST_IAC_SHORT_NAME,
  SECRET_PUSH_PROTECTION,
} from '~/security_configuration/constants';
import { helpPagePath } from '~/helpers/help_page_helper';

import { REPORT_TYPE_SAST, REPORT_TYPE_SAST_IAC } from '~/vue_shared/security_reports/constants';

export const testProjectPath = 'foo/bar';
export const testProviderIds = [101, 102, 103];
export const testProviderName = ['Kontra', 'Secure Code Warrior', 'SecureFlag'];
export const testTrainingUrls = [
  'https://www.vendornameone.com/url',
  'https://www.vendornametwo.com/url',
  'https://www.vendornamethree.com/url',
];

const SAST_DESCRIPTION = 'Analyze your source code for known vulnerabilities.';
const SAST_HELP_PATH = helpPagePath('user/application_security/sast/_index');
const SAST_CONFIG_HELP_PATH = helpPagePath('user/application_security/sast/_index', {
  anchor: 'configuration',
});

const SAST_IAC_DESCRIPTION =
  'Analyze your infrastructure as code configuration files for known vulnerabilities.';
const SAST_IAC_HELP_PATH = helpPagePath('user/application_security/iac_scanning/_index');
const SAST_IAC_CONFIG_HELP_PATH = helpPagePath('user/application_security/iac_scanning/_index', {
  anchor: 'configuration',
});

export const securityFeatures = [
  {
    name: SAST_IAC_NAME,
    shortName: SAST_IAC_SHORT_NAME,
    description: SAST_IAC_DESCRIPTION,
    helpPath: SAST_IAC_HELP_PATH,
    configurationHelpPath: SAST_IAC_CONFIG_HELP_PATH,
    type: REPORT_TYPE_SAST_IAC,
  },
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

export const securityFeaturesMock = [
  {
    name: SAST_NAME,
    shortName: SAST_SHORT_NAME,
    description: SAST_DESCRIPTION,
    helpPath: SAST_HELP_PATH,
    configurationHelpPath: SAST_CONFIG_HELP_PATH,
    type: REPORT_TYPE_SAST,
    available: true,
  },
];

export const secretPushProtectionMock = {
  name: 'Secret push protection',
  description: `Block secrets such as keys and API tokens from being pushed to your repositories.
  'Secret push protection is triggered when commits are pushed to a repository. ' \
  'If any secrets are detected, the push is blocked.`,
  helpPath: SAST_HELP_PATH,
  configurationHelpPath: helpPagePath(
    'user/application_security/secret_detection/secret_push_protection/_index',
  ),
  type: SECRET_PUSH_PROTECTION,
  available: true,
};

export const provideMock = {
  upgradePath: '/upgrade',
  autoDevopsHelpPagePath: '/autoDevopsHelpPagePath',
  autoDevopsPath: '/autoDevopsPath',
  projectFullPath: 'namespace/project',
  vulnerabilityTrainingDocsPath: 'user/application_security/vulnerabilities/_index',
};
