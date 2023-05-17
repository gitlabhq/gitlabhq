export const SEVERITY_CLASSES = {
  info: 'gl-text-blue-400',
  minor: 'gl-text-orange-300',
  major: 'gl-text-orange-400',
  critical: 'gl-text-red-600',
  blocker: 'gl-text-red-800',
  unknown: 'gl-text-gray-400',
};

export const SEVERITY_ICONS = {
  info: 'severity-info',
  minor: 'severity-low',
  major: 'severity-medium',
  critical: 'severity-high',
  blocker: 'severity-critical',
  unknown: 'severity-unknown',
};

export const SEVERITY_ICONS_MR_WIDGET = {
  info: 'severityInfo',
  minor: 'severityLow',
  major: 'severityMedium',
  critical: 'severityHigh',
  blocker: 'severityCritical',
  unknown: 'severityUnknown',
};

export const SEVERITIES = {
  info: {
    class: SEVERITY_CLASSES.info,
    name: SEVERITY_ICONS.info,
  },
  minor: {
    class: SEVERITY_CLASSES.minor,
    name: SEVERITY_ICONS.minor,
  },
  major: {
    class: SEVERITY_CLASSES.major,
    name: SEVERITY_ICONS.major,
  },
  critical: {
    class: SEVERITY_CLASSES.critical,
    name: SEVERITY_ICONS.critical,
  },
  blocker: {
    class: SEVERITY_CLASSES.blocker,
    name: SEVERITY_ICONS.blocker,
  },
  unknown: {
    class: SEVERITY_CLASSES.unknown,
    name: SEVERITY_ICONS.unknown,
  },
};
