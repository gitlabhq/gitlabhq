import { s__ } from '~/locale';

export const I18N_ERROR_TRACKING_SETTINGS = {
  integratedErrorTrackingDisabledText: s__(
    'ErrorTracking|Integrated error tracking is %{epicLinkStart}turned off by default%{epicLinkEnd} and no longer active for this project. To re-enable error tracking on self-hosted instances, you can either %{flagLinkStart}turn on the feature flag%{flagLinkEnd} for integrated error tracking, or provide a Sentry API URL and Auth Token below. However, error tracking is not ready for production use and cannot be enabled on GitLab.com.',
  ),
};
