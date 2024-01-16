import {
  SAST_NAME,
  SAST_SHORT_NAME,
  SAST_IAC_NAME,
  SAST_IAC_SHORT_NAME,
} from '~/security_configuration/constants';
import { __, s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

import {
  REPORT_TYPE_SAST,
  REPORT_TYPE_BREACH_AND_ATTACK_SIMULATION,
  REPORT_TYPE_SAST_IAC,
} from '~/vue_shared/security_reports/constants';

export const testProjectPath = 'foo/bar';
export const testProviderIds = [101, 102, 103];
export const testProviderName = ['Kontra', 'Secure Code Warrior', 'SecureFlag'];
export const testTrainingUrls = [
  'https://www.vendornameone.com/url',
  'https://www.vendornametwo.com/url',
  'https://www.vendornamethree.com/url',
];

const SAST_DESCRIPTION = __('Analyze your source code for known vulnerabilities.');
const SAST_HELP_PATH = helpPagePath('user/application_security/sast/index');
const SAST_CONFIG_HELP_PATH = helpPagePath('user/application_security/sast/index', {
  anchor: 'configuration',
});

const BAS_BADGE_TEXT = s__('SecurityConfiguration|Incubating feature');
const BAS_BADGE_TOOLTIP = s__(
  'SecurityConfiguration|Breach and Attack Simulation is an incubating feature extending existing security testing by simulating adversary activity.',
);
const BAS_DESCRIPTION = s__(
  'SecurityConfiguration|Simulate breach and attack scenarios against your running application by attempting to detect and exploit known vulnerabilities.',
);
const BAS_HELP_PATH = helpPagePath('user/application_security/breach_and_attack_simulation/index');
const BAS_NAME = s__('SecurityConfiguration|Breach and Attack Simulation (BAS)');
const BAS_SHORT_NAME = s__('SecurityConfiguration|BAS');
const BAS_DAST_FEATURE_FLAG_DESCRIPTION = s__(
  'SecurityConfiguration|Enable incubating Breach and Attack Simulation focused features such as callback attacks in your DAST scans.',
);
const BAS_DAST_FEATURE_FLAG_HELP_PATH = helpPagePath(
  'user/application_security/breach_and_attack_simulation/index',
  { anchor: 'extend-dynamic-application-security-testing-dast' },
);
const BAS_DAST_FEATURE_FLAG_NAME = s__(
  'SecurityConfiguration|Out-of-Band Application Security Testing (OAST)',
);

const SAST_IAC_DESCRIPTION = __(
  'Analyze your infrastructure as code configuration files for known vulnerabilities.',
);
const SAST_IAC_HELP_PATH = helpPagePath('user/application_security/iac_scanning/index');
const SAST_IAC_CONFIG_HELP_PATH = helpPagePath('user/application_security/iac_scanning/index', {
  anchor: 'configuration',
});

export const securityFeatures = [
  {
    anchor: 'bas',
    badge: {
      alwaysDisplay: true,
      text: BAS_BADGE_TEXT,
      tooltipText: BAS_BADGE_TOOLTIP,
      variant: 'info',
    },
    description: BAS_DESCRIPTION,
    name: BAS_NAME,
    helpPath: BAS_HELP_PATH,
    secondary: {
      configurationHelpPath: BAS_DAST_FEATURE_FLAG_HELP_PATH,
      description: BAS_DAST_FEATURE_FLAG_DESCRIPTION,
      name: BAS_DAST_FEATURE_FLAG_NAME,
    },
    shortName: BAS_SHORT_NAME,
    type: REPORT_TYPE_BREACH_AND_ATTACK_SIMULATION,
  },
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

export const provideMock = {
  upgradePath: '/upgrade',
  autoDevopsHelpPagePath: '/autoDevopsHelpPagePath',
  autoDevopsPath: '/autoDevopsPath',
  projectFullPath: 'namespace/project',
  vulnerabilityTrainingDocsPath: 'user/application_security/vulnerabilities/index',
};
