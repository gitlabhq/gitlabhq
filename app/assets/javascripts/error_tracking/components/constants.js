export const severityLevel = {
  FATAL: 'fatal',
  ERROR: 'error',
  WARNING: 'warning',
  INFO: 'info',
  DEBUG: 'debug',
};

export const severityLevelVariant = {
  [severityLevel.FATAL]: 'danger',
  [severityLevel.ERROR]: 'neutral',
  [severityLevel.WARNING]: 'warning',
  [severityLevel.INFO]: 'info',
  [severityLevel.DEBUG]: 'muted',
};

export const errorStatus = {
  IGNORED: 'ignored',
  RESOLVED: 'resolved',
  UNRESOLVED: 'unresolved',
};
