import { invert } from 'lodash';

export const FEEDBACK_TYPE_DISMISSAL = 'dismissal';
export const FEEDBACK_TYPE_ISSUE = 'issue';
export const FEEDBACK_TYPE_MERGE_REQUEST = 'merge_request';

/**
 * Security artifact file types
 */
export const REPORT_FILE_TYPES = {
  ARCHIVE: 'ARCHIVE',
  TRACE: 'TRACE',
  METADATA: 'METADATA',
};

/**
 * Security scan report types, as provided by the backend.
 */
export const REPORT_TYPE_SAST = 'sast';
export const REPORT_TYPE_SAST_IAC = 'sast_iac';
export const REPORT_TYPE_DAST = 'dast';
export const REPORT_TYPE_DAST_PROFILES = 'dast_profiles';
export const REPORT_TYPE_SECRET_DETECTION = 'secret_detection';
export const REPORT_TYPE_DEPENDENCY_SCANNING = 'dependency_scanning';
export const REPORT_TYPE_CONTAINER_SCANNING = 'container_scanning';
export const REPORT_TYPE_CONTAINER_SCANNING_FOR_REGISTRY = 'container_scanning_for_registry';
export const REPORT_TYPE_CLUSTER_IMAGE_SCANNING = 'cluster_image_scanning';
export const REPORT_TYPE_COVERAGE_FUZZING = 'coverage_fuzzing';
export const REPORT_TYPE_CORPUS_MANAGEMENT = 'corpus_management';
export const REPORT_TYPE_API_FUZZING = 'api_fuzzing';

/**
 * SecurityReportTypeEnum values for use with GraphQL.
 *
 * These should correspond to the lowercase security scan report types.
 */
export const SECURITY_REPORT_TYPE_ENUM_SAST = 'SAST';
export const SECURITY_REPORT_TYPE_ENUM_SECRET_DETECTION = 'SECRET_DETECTION';

/**
 * A mapping from security scan report types to SecurityReportTypeEnum values.
 */
export const reportTypeToSecurityReportTypeEnum = {
  [REPORT_TYPE_SAST]: SECURITY_REPORT_TYPE_ENUM_SAST,
  [REPORT_TYPE_SECRET_DETECTION]: SECURITY_REPORT_TYPE_ENUM_SECRET_DETECTION,
};

/**
 * A mapping from SecurityReportTypeEnum values to security scan report types.
 */
export const securityReportTypeEnumToReportType = invert(reportTypeToSecurityReportTypeEnum);
