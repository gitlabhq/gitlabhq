import kontraLogo from 'images/vulnerability/kontra-logo.svg?raw';
import scwLogo from 'images/vulnerability/scw-logo.svg?raw';
import secureflagLogo from 'images/vulnerability/secureflag-logo.svg?raw';
import { __, s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

import {
  REPORT_TYPE_SAST,
  REPORT_TYPE_SAST_IAC,
  REPORT_TYPE_SECRET_DETECTION,
} from '~/vue_shared/security_reports/constants';

import configureSastMutation from './graphql/configure_sast.mutation.graphql';
import configureSastIacMutation from './graphql/configure_iac.mutation.graphql';
import configureSecretDetectionMutation from './graphql/configure_secret_detection.mutation.graphql';

/**
 * Translations for Security Configuration Page
 * Make sure to add new scanner translations to the SCANNER_NAMES_MAP below.
 */
export const SAST_NAME = __('Static Application Security Testing (SAST)');
export const SAST_SHORT_NAME = s__('ciReport|SAST');

export const ADVANCED_SAST_NAME = s__('ciReport|Advanced SAST Scanning');

export const SAST_IAC_NAME = __('Infrastructure as Code (IaC) Scanning');
export const SAST_IAC_SHORT_NAME = s__('ciReport|SAST IaC');

export const DAST_NAME = __('Dynamic Application Security Testing (DAST)');
export const DAST_SHORT_NAME = s__('ciReport|DAST');

export const DAST_PROFILES_NAME = __('DAST profiles');
export const DAST_HELP_PATH = helpPagePath('user/application_security/dast/_index');

export const SECRET_DETECTION_NAME = __('Secret Detection');

export const DEPENDENCY_SCANNING_NAME = __('Dependency Scanning');

export const CONTAINER_SCANNING_NAME = __('Container Scanning');

export const CONTAINER_SCANNING_FOR_REGISTRY_NAME = __('Container Scanning For Registry');

export const COVERAGE_FUZZING_NAME = __('Coverage Fuzzing');

export const CORPUS_MANAGEMENT_NAME = __('Corpus Management');

export const API_FUZZING_NAME = __('API Fuzzing');

export const CLUSTER_IMAGE_SCANNING_NAME = s__('ciReport|Cluster Image Scanning');

export const SECRET_PUSH_PROTECTION = 'secret_push_protection';

export const SECRET_PUSH_PROTECTION_NAME = __('Secret push protection');

export const SCANNER_NAMES_MAP = {
  SAST: SAST_SHORT_NAME,
  SAST_ADVANCED: ADVANCED_SAST_NAME,
  SAST_IAC: SAST_IAC_NAME,
  DAST: DAST_SHORT_NAME,
  API_FUZZING: API_FUZZING_NAME,
  CONTAINER_SCANNING: CONTAINER_SCANNING_NAME,
  CONTAINER_SCANNING_FOR_REGISTRY: CONTAINER_SCANNING_FOR_REGISTRY_NAME,
  COVERAGE_FUZZING: COVERAGE_FUZZING_NAME,
  SECRET_DETECTION: SECRET_DETECTION_NAME,
  DEPENDENCY_SCANNING: DEPENDENCY_SCANNING_NAME,
  CLUSTER_IMAGE_SCANNING: CLUSTER_IMAGE_SCANNING_NAME,
  SECRET_PUSH_PROTECTION: SECRET_PUSH_PROTECTION_NAME,
  GENERIC: s__('ciReport|Manually added'),
};

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
  SecureFlag: {
    svg: secureflagLogo,
  },
};

// Use the `url` field from the GraphQL query once this issue is resolved
// https://gitlab.com/gitlab-org/gitlab/-/issues/356129
export const TEMP_PROVIDER_URLS = {
  Kontra: 'https://application.security/',
  [__('Secure Code Warrior')]: 'https://www.securecodewarrior.com/',
  SecureFlag: 'https://www.secureflag.com/',
};

export const TAB_VULNERABILITY_MANAGEMENT_INDEX = 1;

export const TRACK_TOGGLE_TRAINING_PROVIDER_ACTION = 'toggle_security_training_provider';
export const TRACK_TOGGLE_TRAINING_PROVIDER_LABEL = 'update_security_training_provider';
export const TRACK_CLICK_TRAINING_LINK_ACTION = 'click_security_training_link';
export const TRACK_PROVIDER_LEARN_MORE_CLICK_ACTION = 'click_link';
export const TRACK_PROVIDER_LEARN_MORE_CLICK_LABEL = 'security_training_provider';
export const TRACK_TRAINING_LOADED_ACTION = 'security_training_link_loaded';
export const TRACK_PROMOTION_BANNER_CTA_CLICK_ACTION = 'click_button';
export const TRACK_PROMOTION_BANNER_CTA_CLICK_LABEL = 'security_training_promotion_cta';

export const i18n = {
  configurationHistory: s__('SecurityConfiguration|Configuration history'),
  securityTesting: s__('SecurityConfiguration|Security testing'),
  latestPipelineDescription: s__(
    `SecurityConfiguration|The status of the tools only applies to the
       default branch and is based on the %{linkStart}latest pipeline%{linkEnd}.`,
  ),
  description: s__(
    `SecurityConfiguration|Once you've enabled a scan for the default branch,
       any subsequent feature branch you create will include the scan. An enabled
       scanner will not be reflected as such until the pipeline has been
       successfully executed and it has generated valid artifacts.`,
  ),
  securityConfiguration: __('Security configuration'),
  vulnerabilityManagement: s__('SecurityConfiguration|Vulnerability Management'),
  securityTraining: s__('SecurityConfiguration|Security training'),
  securityTrainingDescription: s__(
    'SecurityConfiguration|Enable security training to help your developers learn how to fix vulnerabilities. Developers can view security training from selected educational providers, relevant to the detected vulnerability. Please note that security training is not accessible in an environment that is offline.',
  ),
  securityTrainingDoc: s__('SecurityConfiguration|Learn more about vulnerability training'),
};
