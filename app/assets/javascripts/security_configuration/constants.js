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

export const SAST_IAC_NAME = __('Infrastructure as Code (IaC) Scanning');
export const SAST_IAC_SHORT_NAME = s__('ciReport|SAST IaC');

export const DAST_NAME = __('Dynamic Application Security Testing (DAST)');
export const DAST_SHORT_NAME = s__('ciReport|DAST');

export const DAST_PROFILES_NAME = __('DAST profiles');
export const DAST_HELP_PATH = helpPagePath('user/application_security/dast/_index');

export const SECRET_DETECTION_NAME = __('Secret Detection');

export const DEPENDENCY_SCANNING_NAME = __('Dependency Scanning');

export const CONTAINER_SCANNING_NAME = __('Container Scanning');

export const CORPUS_MANAGEMENT_NAME = __('Corpus Management');

export const SECRET_PUSH_PROTECTION = 'secret_push_protection';

export const SECRET_DETECTION = 'secret_detection';

export const LICENSE_INFORMATION_SOURCE = 'license_information_source';

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
  securityProfiles: s__('SecurityConfiguration|Profile-based scanner configuration'),
  securityProfilesDesc: s__(
    'SecurityConfiguration|Define security settings once and reuse them everywhere. Update a profile and your changes automatically apply to every project that uses the profile, ensuring consistent, predictable security coverage with minimal effort.',
  ),
};

export const SCAN_PROFILE_TYPE_SECRET_DETECTION = 'SECRET_DETECTION';
export const SCAN_PROFILE_CATEGORIES = {
  [SCAN_PROFILE_TYPE_SECRET_DETECTION]: {
    name: s__('SecurityProfiles|Secret Detection'),
    label: 'SD',
    tooltip: s__('SecurityProfiles|Prevents secrets from being pushed to your repository'),
  },
};
export const SCAN_PROFILE_PROMO_ITEMS = [
  { scanType: SCAN_PROFILE_TYPE_SECRET_DETECTION, isConfigured: false },
];
export const SCAN_PROFILE_I18N = {
  noProfile: s__('SecurityProfiles|No profile applied'),
  notConfigured: s__('SecurityProfiles|Not configured'),
  applyToEnable: s__('SecurityProfiles|Apply profile to enable'),
  active: s__('SecurityProfiles|Active'),
  profilesDefine: s__(
    'SecurityProfiles|Profiles define scanner configuration and can be applied to multiple projects',
  ),
  applyDefault: s__('SecurityProfiles|Apply default profile'),
  previewDefault: s__('SecurityProfiles|Preview default profile'),
  disable: s__('SecurityProfiles|Disable'),
  errorLoadingProfiles: s__('SecurityProfiles|Error loading profiles. Please try again.'),
  errorApplying: s__('SecurityProfiles|Error applying profile. Please try again.'),
  errorDetaching: s__('SecurityProfiles|Error detaching profile. Please try again.'),
  successApplying: s__('SecurityProfiles|Profile applied successfully.'),
  successDetaching: s__('SecurityProfiles|Profile disabled successfully.'),
  tooltipTitle: s__('SecurityProfiles|Action unavailable'),
  accessLevelTooltipDescription: s__(
    'SecurityProfiles|Only a project maintainer or owner can apply or disable profiles.',
  ),
};
export const SCAN_PROFILE_STATUS_APPLIED = 'enabled';
export const SCAN_PROFILE_STATUS_MIXED = 'mixed';
export const SCAN_PROFILE_STATUS_DISABLED = 'disabled';
