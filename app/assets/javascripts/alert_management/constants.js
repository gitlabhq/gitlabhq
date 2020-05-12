import { s__ } from '~/locale';

export const ALERTS_STATUS = {
  OPEN: 'open',
  TRIGGERED: 'triggered',
  ACKNOWLEDGED: 'acknowledged',
  RESOLVED: 'resolved',
  ALL: 'all',
};

export const ALERTS_STATUS_TABS = [
  {
    title: s__('AlertManagement|Open'),
    status: ALERTS_STATUS.OPEN,
  },
  {
    title: s__('AlertManagement|Triggered'),
    status: ALERTS_STATUS.TRIGGERED,
  },
  {
    title: s__('AlertManagement|Acknowledged'),
    status: ALERTS_STATUS.ACKNOWLEDGED,
  },
  {
    title: s__('AlertManagement|Resolved'),
    status: ALERTS_STATUS.RESOLVED,
  },
  {
    title: s__('AlertManagement|All alerts'),
    status: ALERTS_STATUS.ALL,
  },
];
