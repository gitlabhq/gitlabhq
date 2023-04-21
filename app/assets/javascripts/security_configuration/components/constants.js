import { helpPagePath } from '~/helpers/help_page_helper';
import { __, s__ } from '~/locale';

import {
  REPORT_TYPE_SAST,
  REPORT_TYPE_SAST_IAC,
  REPORT_TYPE_DAST,
  REPORT_TYPE_DAST_PROFILES,
  REPORT_TYPE_BREACH_AND_ATTACK_SIMULATION,
  REPORT_TYPE_SECRET_DETECTION,
  REPORT_TYPE_DEPENDENCY_SCANNING,
  REPORT_TYPE_CONTAINER_SCANNING,
  REPORT_TYPE_COVERAGE_FUZZING,
  REPORT_TYPE_CORPUS_MANAGEMENT,
  REPORT_TYPE_API_FUZZING,
  REPORT_TYPE_LICENSE_COMPLIANCE,
} from '~/vue_shared/security_reports/constants';

import kontraLogo from 'images/vulnerability/kontra-logo.svg';
import scwLogo from 'images/vulnerability/scw-logo.svg';
import configureSastMutation from '../graphql/configure_sast.mutation.graphql';
import configureSastIacMutation from '../graphql/configure_iac.mutation.graphql';
import configureSecretDetectionMutation from '../graphql/configure_secret_detection.mutation.graphql';

/**
 * Translations & helpPagePaths for Security Configuration Page
 * Make sure to add new scanner translations to the SCANNER_NAMES_MAP below.
 */

export const SAST_NAME = __('Static Application Security Testing (SAST)');
export const SAST_SHORT_NAME = s__('ciReport|SAST');
export const SAST_DESCRIPTION = __('Analyze your source code for known vulnerabilities.');
export const SAST_HELP_PATH = helpPagePath('user/application_security/sast/index');
export const SAST_CONFIG_HELP_PATH = helpPagePath('user/application_security/sast/index', {
  anchor: 'configuration',
});

export const SAST_IAC_NAME = __('Infrastructure as Code (IaC) Scanning');
export const SAST_IAC_SHORT_NAME = s__('ciReport|SAST IaC');
export const SAST_IAC_DESCRIPTION = __(
  'Analyze your infrastructure as code configuration files for known vulnerabilities.',
);
export const SAST_IAC_HELP_PATH = helpPagePath('user/application_security/iac_scanning/index');
export const SAST_IAC_CONFIG_HELP_PATH = helpPagePath(
  'user/application_security/iac_scanning/index',
  {
    anchor: 'configuration',
  },
);

export const DAST_NAME = __('Dynamic Application Security Testing (DAST)');
export const DAST_SHORT_NAME = s__('ciReport|DAST');
export const DAST_DESCRIPTION = s__(
  'ciReport|Analyze a deployed version of your web application for known vulnerabilities by examining it from the outside in. DAST works by simulating external attacks on your application while it is running.',
);
export const DAST_HELP_PATH = helpPagePath('user/application_security/dast/index');
export const DAST_CONFIG_HELP_PATH = helpPagePath('user/application_security/dast/index', {
  anchor: 'enable-automatic-dast-run',
});
export const DAST_BADGE_TEXT = __('Available on-demand');
export const DAST_BADGE_TOOLTIP = __(
  'On-demand scans run outside of the DevOps cycle and find vulnerabilities in your projects',
);

export const DAST_PROFILES_NAME = __('DAST profiles');
export const DAST_PROFILES_DESCRIPTION = s__(
  'SecurityConfiguration|Manage profiles for use by DAST scans.',
);
export const DAST_PROFILES_CONFIG_TEXT = s__('SecurityConfiguration|Manage profiles');

export const BAS_BADGE_TEXT = s__('SecurityConfiguration|Incubating feature');
export const BAS_BADGE_TOOLTIP = s__(
  'SecurityConfiguration|Breach and Attack Simulation is an incubating feature extending existing security testing by simulating adversary activity.',
);
export const BAS_DESCRIPTION = s__(
  'SecurityConfiguration|Simulate breach and attack scenarios against your running application by attempting to detect and exploit known vulnerabilities.',
);
export const BAS_HELP_PATH = helpPagePath(
  'user/application_security/breach_and_attack_simulation/index',
);
export const BAS_NAME = s__('SecurityConfiguration|Breach and Attack Simulation (BAS)');
export const BAS_SHORT_NAME = s__('SecurityConfiguration|BAS');

export const BAS_DAST_FEATURE_FLAG_DESCRIPTION = s__(
  'SecurityConfiguration|Enable incubating Breach and Attack Simulation focused features such as callback attacks in your DAST scans.',
);
export const BAS_DAST_FEATURE_FLAG_HELP_PATH = helpPagePath(
  'user/application_security/breach_and_attack_simulation/index',
  { anchor: 'extend-dynamic-application-security-testing-dast' },
);
export const BAS_DAST_FEATURE_FLAG_NAME = s__(
  'SecurityConfiguration|Out-of-Band Application Security Testing (OAST)',
);

export const SECRET_DETECTION_NAME = __('Secret Detection');
export const SECRET_DETECTION_DESCRIPTION = __(
  'Analyze your source code and git history for secrets.',
);
export const SECRET_DETECTION_HELP_PATH = helpPagePath(
  'user/application_security/secret_detection/index',
);
export const SECRET_DETECTION_CONFIG_HELP_PATH = helpPagePath(
  'user/application_security/secret_detection/index',
  { anchor: 'configuration' },
);

export const DEPENDENCY_SCANNING_NAME = __('Dependency Scanning');
export const DEPENDENCY_SCANNING_DESCRIPTION = __(
  'Analyze your dependencies for known vulnerabilities.',
);
export const DEPENDENCY_SCANNING_HELP_PATH = helpPagePath(
  'user/application_security/dependency_scanning/index',
);
export const DEPENDENCY_SCANNING_CONFIG_HELP_PATH = helpPagePath(
  'user/application_security/dependency_scanning/index',
  { anchor: 'configuration' },
);

export const CONTAINER_SCANNING_NAME = __('Container Scanning');
export const CONTAINER_SCANNING_DESCRIPTION = __(
  'Check your Docker images for known vulnerabilities.',
);
export const CONTAINER_SCANNING_HELP_PATH = helpPagePath(
  'user/application_security/container_scanning/index',
);
export const CONTAINER_SCANNING_CONFIG_HELP_PATH = helpPagePath(
  'user/application_security/container_scanning/index',
  { anchor: 'configuration' },
);

export const COVERAGE_FUZZING_NAME = __('Coverage Fuzzing');
export const COVERAGE_FUZZING_DESCRIPTION = __(
  'Find bugs in your code with coverage-guided fuzzing.',
);
export const COVERAGE_FUZZING_HELP_PATH = helpPagePath(
  'user/application_security/coverage_fuzzing/index',
);
export const COVERAGE_FUZZING_CONFIG_HELP_PATH = helpPagePath(
  'user/application_security/coverage_fuzzing/index',
  { anchor: 'enable-coverage-guided-fuzz-testing' },
);

export const CORPUS_MANAGEMENT_NAME = __('Corpus Management');
export const CORPUS_MANAGEMENT_DESCRIPTION = s__(
  'SecurityConfiguration|Manage corpus files used as seed inputs with coverage-guided fuzzing.',
);
export const CORPUS_MANAGEMENT_CONFIG_TEXT = s__('SecurityConfiguration|Manage corpus');

export const API_FUZZING_NAME = __('API Fuzzing');
export const API_FUZZING_DESCRIPTION = __('Find bugs in your code with API fuzzing.');
export const API_FUZZING_HELP_PATH = helpPagePath('user/application_security/api_fuzzing/index');

export const LICENSE_COMPLIANCE_NAME = __('License Compliance');
export const LICENSE_COMPLIANCE_DESCRIPTION = __(
  'Search your project dependencies for their licenses and apply policies.',
);
export const LICENSE_COMPLIANCE_HELP_PATH = helpPagePath(
  'user/compliance/license_compliance/index',
);

export const CLUSTER_IMAGE_SCANNING_NAME = s__('ciReport|Cluster Image Scanning');

export const SCANNER_NAMES_MAP = {
  SAST: SAST_SHORT_NAME,
  SAST_IAC: SAST_IAC_NAME,
  DAST: DAST_SHORT_NAME,
  API_FUZZING: API_FUZZING_NAME,
  CONTAINER_SCANNING: CONTAINER_SCANNING_NAME,
  COVERAGE_FUZZING: COVERAGE_FUZZING_NAME,
  SECRET_DETECTION: SECRET_DETECTION_NAME,
  DEPENDENCY_SCANNING: DEPENDENCY_SCANNING_NAME,
  BREACH_AND_ATTACK_SIMULATION: BAS_NAME,
  CLUSTER_IMAGE_SCANNING: CLUSTER_IMAGE_SCANNING_NAME,
  GENERIC: s__('ciReport|Manually added'),
};

export const securityFeatures = [
  {
    name: SAST_NAME,
    shortName: SAST_SHORT_NAME,
    description: SAST_DESCRIPTION,
    helpPath: SAST_HELP_PATH,
    configurationHelpPath: SAST_CONFIG_HELP_PATH,
    type: REPORT_TYPE_SAST,
  },
  {
    name: SAST_IAC_NAME,
    shortName: SAST_IAC_SHORT_NAME,
    description: SAST_IAC_DESCRIPTION,
    helpPath: SAST_IAC_HELP_PATH,
    configurationHelpPath: SAST_IAC_CONFIG_HELP_PATH,
    type: REPORT_TYPE_SAST_IAC,
  },
  {
    badge: {
      text: DAST_BADGE_TEXT,
      tooltipText: DAST_BADGE_TOOLTIP,
      variant: 'info',
    },
    secondary: {
      type: REPORT_TYPE_DAST_PROFILES,
      name: DAST_PROFILES_NAME,
      description: DAST_PROFILES_DESCRIPTION,
      configurationText: DAST_PROFILES_CONFIG_TEXT,
    },
    name: DAST_NAME,
    shortName: DAST_SHORT_NAME,
    description: DAST_DESCRIPTION,
    helpPath: DAST_HELP_PATH,
    configurationHelpPath: DAST_CONFIG_HELP_PATH,
    type: REPORT_TYPE_DAST,
    anchor: 'dast',
  },
  {
    name: DEPENDENCY_SCANNING_NAME,
    description: DEPENDENCY_SCANNING_DESCRIPTION,
    helpPath: DEPENDENCY_SCANNING_HELP_PATH,
    configurationHelpPath: DEPENDENCY_SCANNING_CONFIG_HELP_PATH,
    type: REPORT_TYPE_DEPENDENCY_SCANNING,
    anchor: 'dependency-scanning',
  },
  {
    name: CONTAINER_SCANNING_NAME,
    description: CONTAINER_SCANNING_DESCRIPTION,
    helpPath: CONTAINER_SCANNING_HELP_PATH,
    configurationHelpPath: CONTAINER_SCANNING_CONFIG_HELP_PATH,
    type: REPORT_TYPE_CONTAINER_SCANNING,
  },
  {
    name: SECRET_DETECTION_NAME,
    description: SECRET_DETECTION_DESCRIPTION,
    helpPath: SECRET_DETECTION_HELP_PATH,
    configurationHelpPath: SECRET_DETECTION_CONFIG_HELP_PATH,
    type: REPORT_TYPE_SECRET_DETECTION,
  },
  {
    name: API_FUZZING_NAME,
    description: API_FUZZING_DESCRIPTION,
    helpPath: API_FUZZING_HELP_PATH,
    type: REPORT_TYPE_API_FUZZING,
  },
  {
    name: COVERAGE_FUZZING_NAME,
    description: COVERAGE_FUZZING_DESCRIPTION,
    helpPath: COVERAGE_FUZZING_HELP_PATH,
    configurationHelpPath: COVERAGE_FUZZING_CONFIG_HELP_PATH,
    type: REPORT_TYPE_COVERAGE_FUZZING,
    secondary: {
      type: REPORT_TYPE_CORPUS_MANAGEMENT,
      name: CORPUS_MANAGEMENT_NAME,
      description: CORPUS_MANAGEMENT_DESCRIPTION,
      configurationText: CORPUS_MANAGEMENT_CONFIG_TEXT,
    },
  },
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
];

export const complianceFeatures = [
  {
    name: LICENSE_COMPLIANCE_NAME,
    description: LICENSE_COMPLIANCE_DESCRIPTION,
    helpPath: LICENSE_COMPLIANCE_HELP_PATH,
    type: REPORT_TYPE_LICENSE_COMPLIANCE,
  },
];

export const featureToMutationMap = {
  [REPORT_TYPE_SAST]: {
    mutationId: 'configureSast',
    getMutationPayload: (projectPath) => ({
      mutation: configureSastMutation,
      variables: {
        input: {
          projectPath,
          configuration: { global: [], pipeline: [], analyzers: [] },
        },
      },
    }),
  },
  [REPORT_TYPE_SAST_IAC]: {
    mutationId: 'configureSastIac',
    getMutationPayload: (projectPath) => ({
      mutation: configureSastIacMutation,
      variables: {
        input: {
          projectPath,
        },
      },
    }),
  },
  [REPORT_TYPE_SECRET_DETECTION]: {
    mutationId: 'configureSecretDetection',
    getMutationPayload: (projectPath) => ({
      mutation: configureSecretDetectionMutation,
      variables: {
        input: {
          projectPath,
        },
      },
    }),
  },
};

export const AUTO_DEVOPS_ENABLED_ALERT_DISMISSED_STORAGE_KEY =
  'security_configuration_auto_devops_enabled_dismissed_projects';

// Fetch the svg path from the GraphQL query once this issue is resolved
// https://gitlab.com/gitlab-org/gitlab/-/issues/346899
export const TEMP_PROVIDER_LOGOS = {
  Kontra: {
    svg: kontraLogo,
  },
  [__('Secure Code Warrior')]: {
    svg: scwLogo,
  },
};

// Use the `url` field from the GraphQL query once this issue is resolved
// https://gitlab.com/gitlab-org/gitlab/-/issues/356129
export const TEMP_PROVIDER_URLS = {
  Kontra: 'https://application.security/',
  [__('Secure Code Warrior')]: 'https://www.securecodewarrior.com/',
};
