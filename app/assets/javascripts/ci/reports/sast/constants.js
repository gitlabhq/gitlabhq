export const SEVERITY_CLASSES = {
  info: 'gl-text-blue-400',
  low: 'gl-text-orange-300',
  medium: 'gl-text-orange-400',
  high: 'gl-text-red-600',
  critical: 'gl-text-red-800',
  unknown: 'gl-text-gray-400',
};

export const SEVERITY_ICONS = {
  info: 'severity-info',
  low: 'severity-low',
  medium: 'severity-medium',
  high: 'severity-high',
  critical: 'severity-critical',
  unknown: 'severity-unknown',
};

export const SEVERITIES = {
  info: {
    class: SEVERITY_CLASSES.info,
    name: SEVERITY_ICONS.info,
  },
  low: {
    class: SEVERITY_CLASSES.low,
    name: SEVERITY_ICONS.low,
  },
  medium: {
    class: SEVERITY_CLASSES.medium,
    name: SEVERITY_ICONS.medium,
  },
  high: {
    class: SEVERITY_CLASSES.high,
    name: SEVERITY_ICONS.high,
  },
  critical: {
    class: SEVERITY_CLASSES.critical,
    name: SEVERITY_ICONS.critical,
  },
  unknown: {
    class: SEVERITY_CLASSES.unknown,
    name: SEVERITY_ICONS.unknown,
  },
};
