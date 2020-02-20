export const severityLevel = {
  FATAL: 'fatal',
  ERROR: 'error',
  WARNING: 'warning',
  INFO: 'info',
  DEBUG: 'debug',
};

export const severityLevelVariant = {
  [severityLevel.FATAL]: 'danger',
  [severityLevel.ERROR]: 'dark',
  [severityLevel.WARNING]: 'warning',
  [severityLevel.INFO]: 'info',
  [severityLevel.DEBUG]: 'light',
};

export const errorStatus = {
  IGNORED: 'ignored',
  RESOLVED: 'resolved',
  UNRESOLVED: 'unresolved',
};
