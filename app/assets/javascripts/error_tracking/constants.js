import { s__ } from '~/locale';

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

export const I18N_ERROR_TRACKING_LIST = {
  integratedErrorTrackingDisabledText: s__(
    'ErrorTracking|Integrated error tracking is %{epicLinkStart}turned off by default%{epicLinkEnd} and no longer active for this project. To re-enable error tracking on self-hosted instances, you can either %{flagLinkStart}turn on the feature flag%{flagLinkEnd} for integrated error tracking, or provide a %{settingsLinkStart}Sentry API URL and Auth Token%{settingsLinkEnd} on your project settings page. However, error tracking is not ready for production use and cannot be enabled on GitLab.com.',
  ),
  viewProjectSettingsButton: s__('ErrorTracking|View project settings'),
};
