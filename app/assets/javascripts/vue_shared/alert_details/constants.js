import { s__ } from '~/locale';

export const SEVERITY_LEVELS = {
  CRITICAL: s__('severity|Critical'),
  HIGH: s__('severity|High'),
  MEDIUM: s__('severity|Medium'),
  LOW: s__('severity|Low'),
  INFO: s__('severity|Info'),
  UNKNOWN: s__('severity|Unknown'),
};

/* eslint-disable @gitlab/require-i18n-strings */
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
      category: 'Alert Management',
      action: 'view_alert_details',
    },
    // Tracks snowplow event when alert status is updated
    TRACK_ALERT_STATUS_UPDATE_OPTIONS: {
      category: 'Alert Management',
      action: 'update_alert_status',
      label: 'Status',
    },
  },
  THREAT_MONITORING: {
    TITLE: 'THREAT_MONITORING',
    STATUSES: {
      TRIGGERED: s__('ThreatMonitoring|Unreviewed'),
      ACKNOWLEDGED: s__('ThreatMonitoring|In review'),
      RESOLVED: s__('ThreatMonitoring|Resolved'),
      IGNORED: s__('ThreatMonitoring|Dismissed'),
    },
  },
};
