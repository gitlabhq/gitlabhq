export const BLOCKERS_ROUTE = 'index';
export const CODE_QUALITY_ROUTE = 'code-quality';
export const SECURITY_SCAN_ROUTE = 'security-scan';
export const LICENSE_COMPLIANCE_ROUTE = 'license-compliance';

export const VIEW_MERGE_REQUEST_REPORT = 'view_merge_request_report';
export const CLICK_TAB_ON_MERGE_REQUEST_REPORT = 'click_tab_on_merge_request_report';
export const CLICK_VIEW_REPORT_ON_MERGE_REQUEST_WIDGET =
  'click_view_report_on_merge_request_widget';

// Tracking labels use snake_case to match the internal events metric YAML convention.
export const TRACKING_LABEL_BY_ROUTE = {
  [SECURITY_SCAN_ROUTE]: 'security_scan',
  [LICENSE_COMPLIANCE_ROUTE]: 'license_compliance',
  [CODE_QUALITY_ROUTE]: 'code_quality',
};
