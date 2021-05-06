import { helpPagePath } from '~/helpers/help_page_helper';
import { __, s__ } from '~/locale';

import configureSastMutation from '~/security_configuration/graphql/configure_sast.mutation.graphql';
import {
  REPORT_TYPE_SAST,
  REPORT_TYPE_DAST,
  REPORT_TYPE_DAST_PROFILES,
  REPORT_TYPE_SECRET_DETECTION,
  REPORT_TYPE_DEPENDENCY_SCANNING,
  REPORT_TYPE_CONTAINER_SCANNING,
  REPORT_TYPE_COVERAGE_FUZZING,
  REPORT_TYPE_API_FUZZING,
  REPORT_TYPE_LICENSE_COMPLIANCE,
} from '~/vue_shared/security_reports/constants';

/**
 * Translations & helpPagePaths for Static Security Configuration Page
 */
export const SAST_NAME = __('Static Application Security Testing (SAST)');
export const SAST_DESCRIPTION = __('Analyze your source code for known vulnerabilities.');
export const SAST_HELP_PATH = helpPagePath('user/application_security/sast/index');

export const DAST_NAME = __('Dynamic Application Security Testing (DAST)');
export const DAST_DESCRIPTION = __('Analyze a review version of your web application.');
export const DAST_HELP_PATH = helpPagePath('user/application_security/dast/index');

export const DAST_PROFILES_NAME = __('DAST Scans');
export const DAST_PROFILES_DESCRIPTION = __(
  'Saved scan settings and target site settings which are reusable.',
);
export const DAST_PROFILES_HELP_PATH = helpPagePath('user/application_security/dast/index');

export const SECRET_DETECTION_NAME = __('Secret Detection');
export const SECRET_DETECTION_DESCRIPTION = __(
  'Analyze your source code and git history for secrets.',
);
export const SECRET_DETECTION_HELP_PATH = helpPagePath(
  'user/application_security/secret_detection/index',
);

export const DEPENDENCY_SCANNING_NAME = __('Dependency Scanning');
export const DEPENDENCY_SCANNING_DESCRIPTION = __(
  'Analyze your dependencies for known vulnerabilities.',
);
export const DEPENDENCY_SCANNING_HELP_PATH = helpPagePath(
  'user/application_security/dependency_scanning/index',
);

export const CONTAINER_SCANNING_NAME = __('Container Scanning');
export const CONTAINER_SCANNING_DESCRIPTION = __(
  'Check your Docker images for known vulnerabilities.',
);
export const CONTAINER_SCANNING_HELP_PATH = helpPagePath(
  'user/application_security/container_scanning/index',
);

export const COVERAGE_FUZZING_NAME = __('Coverage Fuzzing');
export const COVERAGE_FUZZING_DESCRIPTION = __(
  'Find bugs in your code with coverage-guided fuzzing.',
);
export const COVERAGE_FUZZING_HELP_PATH = helpPagePath(
  'user/application_security/coverage_fuzzing/index',
);

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

export const UPGRADE_CTA = s__(
  'SecurityConfiguration|Available with %{linkStart}upgrade or free trial%{linkEnd}',
);

export const scanners = [
  {
    name: SAST_NAME,
    description: SAST_DESCRIPTION,
    helpPath: SAST_HELP_PATH,
    type: REPORT_TYPE_SAST,
  },
  {
    name: DAST_NAME,
    description: DAST_DESCRIPTION,
    helpPath: DAST_HELP_PATH,
    type: REPORT_TYPE_DAST,
  },
  {
    name: DAST_PROFILES_NAME,
    description: DAST_PROFILES_DESCRIPTION,
    helpPath: DAST_PROFILES_HELP_PATH,
    type: REPORT_TYPE_DAST_PROFILES,
  },
  {
    name: DEPENDENCY_SCANNING_NAME,
    description: DEPENDENCY_SCANNING_DESCRIPTION,
    helpPath: DEPENDENCY_SCANNING_HELP_PATH,
    type: REPORT_TYPE_DEPENDENCY_SCANNING,
  },
  {
    name: CONTAINER_SCANNING_NAME,
    description: CONTAINER_SCANNING_DESCRIPTION,
    helpPath: CONTAINER_SCANNING_HELP_PATH,
    type: REPORT_TYPE_CONTAINER_SCANNING,
  },
  {
    name: SECRET_DETECTION_NAME,
    description: SECRET_DETECTION_DESCRIPTION,
    helpPath: SECRET_DETECTION_HELP_PATH,
    type: REPORT_TYPE_SECRET_DETECTION,
  },
  {
    name: COVERAGE_FUZZING_NAME,
    description: COVERAGE_FUZZING_DESCRIPTION,
    helpPath: COVERAGE_FUZZING_HELP_PATH,
    type: REPORT_TYPE_COVERAGE_FUZZING,
  },
  {
    name: API_FUZZING_NAME,
    description: API_FUZZING_DESCRIPTION,
    helpPath: API_FUZZING_HELP_PATH,
    type: REPORT_TYPE_API_FUZZING,
  },
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
};
