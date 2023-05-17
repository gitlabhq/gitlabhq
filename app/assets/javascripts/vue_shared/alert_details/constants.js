import { s__ } from '~/locale';

export const SEVERITY_LEVELS = {
  CRITICAL: s__('severity|Critical'),
  HIGH: s__('severity|High'),
  MEDIUM: s__('severity|Medium'),
  LOW: s__('severity|Low'),
  INFO: s__('severity|Info'),
  UNKNOWN: s__('severity|Unknown'),
};

const category = 'Alert Management'; // eslint-disable-line @gitlab/require-i18n-strings

export const PAGE_CONFIG = {
  OPERATIONS: {
    TITLE: 'OPERATIONS',
    STATUSES: {
      TRIGGERED: s__('AlertManagement|Triggered'),
      ACKNOWLEDGED: s__('AlertManagement|Acknowledged'),
      RESOLVED: s__('AlertManagement|Resolved'),
    },
    // Tracks snowplow event when user views alert details
    TRACK_ALERTS_DETAILS_VIEWS_OPTIONS: {
      category,
      action: 'view_alert_details',
    },
    // Tracks snowplow event when alert status is updated
    TRACK_ALERT_STATUS_UPDATE_OPTIONS: {
      category,
      action: 'update_alert_status',
      label: 'Status', // eslint-disable-line @gitlab/require-i18n-strings
    },
  },
};
