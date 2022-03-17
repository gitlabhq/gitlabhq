export const SEVERITY_CLASSES = {
  info: 'text-primary-400',
  minor: 'text-warning-200',
  major: 'text-warning-400',
  critical: 'text-danger-600',
  blocker: 'text-danger-800',
  unknown: 'text-secondary-400',
};

export const SEVERITY_ICONS = {
  info: 'severity-info',
  minor: 'severity-low',
  major: 'severity-medium',
  critical: 'severity-high',
  blocker: 'severity-critical',
  unknown: 'severity-unknown',
};

// This is the icons mapping for the code Quality Merge-Request Widget Extension
// once the refactor_mr_widgets_extensions flag is activated the above SEVERITY_ICONS
// need be removed and this variable needs to be rename to SEVERITY_ICONS
// Rollout Issue: https://gitlab.com/gitlab-org/gitlab/-/issues/341759

export const SEVERITY_ICONS_EXTENSION = {
  info: 'severityInfo',
  minor: 'severityLow',
  major: 'severityMedium',
  critical: 'severityHigh',
  blocker: 'severityCritical',
  unknown: 'severityUnknown',
};
