import { s__ } from '~/locale';

export const SEVERITY_LEVELS = {
  CRITICAL: s__('severity|Critical'),
  HIGH: s__('severity|High'),
  MEDIUM: s__('severity|Medium'),
  LOW: s__('severity|Low'),
  INFO: s__('severity|Info'),
  UNKNOWN: s__('severity|Unknown'),
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

/**
 * Tracks snowplow event when user views alerts list
 */
export const trackAlertListViewsOptions = {
  category: 'Alert Management', // eslint-disable-line @gitlab/require-i18n-strings
  action: 'view_alerts_list',
};
