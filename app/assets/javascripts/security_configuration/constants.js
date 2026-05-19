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

export const CVS_CONTAINER_SCANNING = 'cvs_for_container_scanning';

export const CVS_DEPENDENCY_SCANNING = 'cvs_for_dependency_scanning';

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

// tracking for security training
export const TRACK_TOGGLE_TRAINING_PROVIDER_ACTION = 'toggle_security_training_provider';
export const TRACK_TOGGLE_TRAINING_PROVIDER_LABEL = 'update_security_training_provider';
export const TRACK_CLICK_TRAINING_LINK_ACTION = 'click_security_training_link';
export const TRACK_PROVIDER_LEARN_MORE_CLICK_ACTION = 'click_link';
export const TRACK_PROVIDER_LEARN_MORE_CLICK_LABEL = 'security_training_provider';
export const TRACK_TRAINING_LOADED_ACTION = 'security_training_link_loaded';

// tracking for scan profiles
export const EVENT_VIEW_SCAN_PROFILE_TABLE = 'view_scan_profile_list';
export const EVENT_CLICK_SCAN_PROFILE_LEARN_MORE_LINK = 'click_scan_profile_learn_more_link';
export const EVENT_PREVIEW_SCAN_PROFILE = 'preview_scan_profile';

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
export const SCAN_PROFILE_TYPE_SAST = 'SAST';
export const SCAN_PROFILE_TYPE_DEPENDENCY_SCANNING = 'DEPENDENCY_SCANNING';

export const SCAN_TRIGGER_DEFINITIONS = {
  GIT_PUSH_EVENT: {
    anchor: 'secret-push-protection',
    icon: 'push-rules',
    title: s__('ScanProfiles|Secret push protection'),
    subtitle: s__('ScanProfiles|Scan all Git push events and block pushes with detected secrets.'),
    description: s__(
      'ScanProfiles|Block secrets such as keys and API tokens from being pushed to your repositories. Secret detection is triggered when commits are pushed to a repository. If any secrets are detected, the push is blocked.',
    ),
    helpLink: helpPagePath(
      '/user/application_security/secret_detection/secret_push_protection/_index.md',
    ),
  },
  MERGE_REQUEST_PIPELINE: {
    anchor: 'merge-request-pipeline',
    icon: 'merge-request',
    title: s__('ScanProfiles|Merge Request Pipelines'),
    subtitle: s__('ScanProfiles|Scans new commits to merge requests · All branches'),
    description: s__(
      'ScanProfiles|A scan is automatically run each time new commits are pushed to a branch associated with an open merge request. The full repository is scanned, but only vulnerabilities introduced by the merge request are highlighted. This helps identify security issues early, before code is merged.',
    ),
    targetBranch: s__('ScanProfiles|All'),
    scope: s__('ScanProfiles|Full repository'),
    results: s__('ScanProfiles|New vulnerabilities only'),
  },
  DEFAULT_BRANCH_PIPELINE: {
    anchor: 'default-branch-pipeline',
    icon: 'branch',
    title: s__('ScanProfiles|Branch Pipelines (default only)'),
    subtitle: s__('ScanProfiles|Scans commits to the default branch'),
    description: s__(
      "ScanProfiles|A scan is automatically run when changes are merged or pushed to the default branch. All vulnerabilities found are reported, providing a complete picture of your default branch's security posture.",
    ),
    targetBranch: s__('ScanProfiles|Default'),
    scope: s__('ScanProfiles|Full repository'),
    results: s__('ScanProfiles|All vulnerabilities'),
  },
};

export const SCAN_PROFILE_CATEGORIES = {
  [SCAN_PROFILE_TYPE_SECRET_DETECTION]: {
    name: s__('SecurityProfiles|Secret Detection'),
    displayName: s__('SecurityProfiles|Secret Detection'),
    label: 'SD',
    helpTitle: s__('SecurityProfiles|What is secret push protection?'),
    helpDescription: s__(
      'SecurityProfiles|Block secrets such as keys and API tokens from being pushed to your repositories. Secret push protection is triggered when commits are pushed to a repository. If any secrets are detected, the push is blocked. %{linkStart}Learn more%{linkEnd}.',
    ),
    helpLink: helpPagePath(
      '/user/application_security/configuration/security_configuration_profiles',
    ),
  },
  [SCAN_PROFILE_TYPE_SAST]: {
    name: s__('SecurityProfiles|SAST'),
    displayName: s__('SecurityProfiles|Static Application Security Testing (SAST)'),
    label: 'SAST',
    helpTitle: s__('SecurityProfiles|What is SAST?'),
    helpDescription: s__(
      'SecurityProfiles|Scans your source code using GitLab-managed rules to identify common vulnerabilities like injection flaws and hardcoded secrets. %{linkStart}Learn more%{linkEnd}.',
    ),
    helpLink: helpPagePath('/user/application_security/sast/_index'),
  },
  [SCAN_PROFILE_TYPE_DEPENDENCY_SCANNING]: {
    name: s__('SecurityProfiles|Dependency Scanning'),
    displayName: s__('SecurityProfiles|Dependency Scanning'),
    label: 'DS',
    helpTitle: s__('SecurityProfiles|What is Dependency Scanning?'),
    helpDescription: s__(
      "SecurityProfiles|Scans your project's dependencies for known vulnerabilities to identify security risks introduced by third-party packages. %{linkStart}Learn more%{linkEnd}.",
    ),
    helpLink: helpPagePath('/user/application_security/dependency_scanning/_index'),
  },
};

export const SCAN_PROFILE_PROMO_ITEMS = [
  { scanType: SCAN_PROFILE_TYPE_SECRET_DETECTION, isConfigured: false },
  { scanType: SCAN_PROFILE_TYPE_SAST, isConfigured: false },
  { scanType: SCAN_PROFILE_TYPE_DEPENDENCY_SCANNING, isConfigured: false },
];

export const SCAN_PROFILE_I18N = {
  noProfile: s__('SecurityProfiles|No profile applied'),
  notConfigured: s__('SecurityProfiles|Unconfigured'),
  applyToEnable: s__('SecurityProfiles|Apply profile to enable'),
  awaitingFirstPipeline: s__('SecurityProfiles|Awaiting first pipeline'),
  coverageMayBeOutdated: s__('SecurityProfiles|Coverage may be outdated'),
  active: s__('SecurityProfiles|Active'),
  profileHelpTitle: s__('SecurityProfiles|What are configuration profiles?'),
  profileHelpDescription: s__(
    'SecurityProfiles|Configuration profiles are reusable settings templates for security tools. Create and manage profiles once, then apply them to multiple projects to ensure consistent security coverage. %{linkStart}Learn more%{linkEnd}.',
  ),
  applyDefault: s__('SecurityProfiles|Apply default profile'),
  previewDefault: s__('SecurityProfiles|Preview default profile'),
  disable: s__('SecurityProfiles|Disable'),
  troubleshootFailure: s__('SecurityProfiles|Troubleshoot failure'),
  errorLoadingProfiles: s__('SecurityProfiles|Error loading profiles. Please try again.'),
  errorLoadingStatuses: s__('SecurityProfiles|Error loading statuses. Please try again.'),
  errorApplying: s__('SecurityProfiles|Error applying profile. Please try again.'),
  errorDetaching: s__('SecurityProfiles|Error detaching profile. Please try again.'),
  errorLoadingJobData: s__('SecurityProfiles|Failed to load scan details. Please try again.'),
  errorLoadingJobLink: s__('SecurityProfiles|The job link failed to load. Please try again.'),
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

export const SCAN_PROFILE_SCANNER_HEALTH_PENDING = 'pending';
export const SCAN_PROFILE_SCANNER_HEALTH_UNCONFIGURED = 'unconfigured';
export const SCAN_PROFILE_SCANNER_HEALTH_ACTIVE = 'active';
export const SCAN_PROFILE_SCANNER_HEALTH_WARNING = 'warning';
export const SCAN_PROFILE_SCANNER_HEALTH_FAILED = 'failed';
export const SCAN_PROFILE_SCANNER_HEALTH_STALE = 'stale';

export const SCAN_PROFILE_SOURCE_LABELS = {
  push: __('Push'),
  web: __('Web'),
  webide: __('Web IDE'),
  api: __('API'),
  merge_request_event: __('Merge request'),
  schedule: __('Schedule'),
  trigger: __('Trigger'),
  pipeline: __('Pipeline'),
  parent_pipeline: __('Parent pipeline'),
  external_pull_request_event: __('External pull request'),
  external: __('External'),
  scan_execution_policy: __('Scan execution policy'),
  pipeline_execution_policy: __('Pipeline execution policy'),
  pipeline_execution_policy_schedule: __('Scheduled policy'),
  security_orchestration_policy: __('Security policy'),
  security_scan_profiles: __('Security profile'),
  ondemand_dast_scan: __('On-demand DAST scan'),
  ondemand_dast_validation: __('On-demand DAST validation'),
  duo_workflow: __('Duo workflow'),
  container_registry_push: __('Container registry push'),
  chat: __('Unknown'),
};
