import { helpPagePath } from '~/helpers/help_page_helper';
import { s__ } from '~/locale';

import {
  REPORT_TYPE_SAST,
  REPORT_TYPE_DAST,
  REPORT_TYPE_DAST_PROFILES,
  REPORT_TYPE_SECRET_DETECTION,
  REPORT_TYPE_DEPENDENCY_SCANNING,
  REPORT_TYPE_CONTAINER_SCANNING,
  REPORT_TYPE_COVERAGE_FUZZING,
  REPORT_TYPE_LICENSE_COMPLIANCE,
} from '~/vue_shared/security_reports/constants';

/**
 * Translations & helpPagePaths for Static Security Configuration Page
 */
export const SAST_NAME = s__('Static Application Security Testing (SAST)');
export const SAST_DESCRIPTION = s__('Analyze your source code for known vulnerabilities.');
export const SAST_HELP_PATH = helpPagePath('user/application_security/sast/index');

export const DAST_NAME = s__('Dynamic Application Security Testing (DAST)');
export const DAST_DESCRIPTION = s__('Analyze a review version of your web application.');
export const DAST_HELP_PATH = helpPagePath('user/application_security/dast/index');

export const DAST_PROFILES_NAME = s__('DAST Scans');
export const DAST_PROFILES_DESCRIPTION = s__('Analyze a review version of your web application.');
export const DAST_PROFILES_HELP_PATH = helpPagePath('user/application_security/dast/index');

export const SECRET_DETECTION_NAME = s__('Secret Detection');
export const SECRET_DETECTION_DESCRIPTION = s__(
  'Analyze your source code and git history for secrets.',
);
export const SECRET_DETECTION_HELP_PATH = helpPagePath(
  'user/application_security/secret_detection/index',
);

export const DEPENDENCY_SCANNING_NAME = s__('Dependency Scanning');
export const DEPENDENCY_SCANNING_DESCRIPTION = s__(
  'Analyze your dependencies for known vulnerabilities.',
);
export const DEPENDENCY_SCANNING_HELP_PATH = helpPagePath(
  'user/application_security/dependency_scanning/index',
);

export const CONTAINER_SCANNING_NAME = s__('Container Scanning');
export const CONTAINER_SCANNING_DESCRIPTION = s__(
  'Check your Docker images for known vulnerabilities.',
);
export const CONTAINER_SCANNING_HELP_PATH = helpPagePath(
  'user/application_security/container_scanning/index',
);

export const COVERAGE_FUZZING_NAME = s__('Coverage Fuzzing');
export const COVERAGE_FUZZING_DESCRIPTION = s__(
  'Find bugs in your code with coverage-guided fuzzing.',
);
export const COVERAGE_FUZZING_HELP_PATH = helpPagePath(
  'user/application_security/coverage_fuzzing/index',
);

export const LICENSE_COMPLIANCE_NAME = s__('License Compliance');
export const LICENSE_COMPLIANCE_DESCRIPTION = s__(
  'Search your project dependencies for their licenses and apply policies.',
);
export const LICENSE_COMPLIANCE_HELP_PATH = helpPagePath(
  'user/compliance/license_compliance/index',
);

export const UPGRADE_CTA = s__(
  'SecurityConfiguration|Available with %{linkStart}upgrade or free trial%{linkEnd}',
);

export const features = [
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
    name: SECRET_DETECTION_NAME,
    description: SECRET_DETECTION_DESCRIPTION,
    helpPath: SECRET_DETECTION_HELP_PATH,
    type: REPORT_TYPE_SECRET_DETECTION,
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
    name: COVERAGE_FUZZING_NAME,
    description: COVERAGE_FUZZING_DESCRIPTION,
    helpPath: COVERAGE_FUZZING_HELP_PATH,
    type: REPORT_TYPE_COVERAGE_FUZZING,
  },
  {
    name: LICENSE_COMPLIANCE_NAME,
    description: LICENSE_COMPLIANCE_DESCRIPTION,
    helpPath: LICENSE_COMPLIANCE_HELP_PATH,
    type: REPORT_TYPE_LICENSE_COMPLIANCE,
  },
];
