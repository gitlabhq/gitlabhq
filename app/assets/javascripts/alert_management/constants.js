import { s__ } from '~/locale';

export const ALERTS_SEVERITY_LABELS = {
  CRITICAL: s__('AlertManagement|Critical'),
  HIGH: s__('AlertManagement|High'),
  MEDIUM: s__('AlertManagement|Medium'),
  LOW: s__('AlertManagement|Low'),
  INFO: s__('AlertManagement|Info'),
  UNKNOWN: s__('AlertManagement|Unknown'),
};

export const ALERTS_STATUS_TABS = [
  {
    title: s__('AlertManagement|Open'),
    status: 'OPEN',
    filters: ['TRIGGERED', 'ACKNOWLEDGED'],
  },
  {
    title: s__('AlertManagement|Triggered'),
    status: 'TRIGGERED',
    filters: 'TRIGGERED',
  },
  {
    title: s__('AlertManagement|Acknowledged'),
    status: 'ACKNOWLEDGED',
    filters: 'ACKNOWLEDGED',
  },
  {
    title: s__('AlertManagement|Resolved'),
    status: 'RESOLVED',
    filters: 'RESOLVED',
  },
  {
    title: s__('AlertManagement|All alerts'),
    status: 'ALL',
    filters: ['TRIGGERED', 'ACKNOWLEDGED', 'RESOLVED'],
  },
];

/* eslint-disable @gitlab/require-i18n-strings */

/**
 * Tracks snowplow event when user views alerts list
 */
export const trackAlertListViewsOptions = {
  category: 'Alert Management',
  action: 'view_alerts_list',
};

/**
 * Tracks snowplow event when user views alert details
 */
export const trackAlertsDetailsViewsOptions = {
  category: 'Alert Management',
  action: 'view_alert_details',
};

/**
 * Tracks snowplow event when alert status is updated
 */
export const trackAlertStatusUpdateOptions = {
  category: 'Alert Management',
  action: 'update_alert_status',
  label: 'Status',
};
