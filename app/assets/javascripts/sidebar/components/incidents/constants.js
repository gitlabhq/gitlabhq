import { s__ } from '~/locale';

export const STATUS_TRIGGERED = 'TRIGGERED';
export const STATUS_ACKNOWLEDGED = 'ACKNOWLEDGED';
export const STATUS_RESOLVED = 'RESOLVED';

export const STATUS_TRIGGERED_LABEL = s__('IncidentManagement|Triggered');
export const STATUS_ACKNOWLEDGED_LABEL = s__('IncidentManagement|Acknowledged');
export const STATUS_RESOLVED_LABEL = s__('IncidentManagement|Resolved');

export const STATUS_LABELS = {
  [STATUS_TRIGGERED]: STATUS_TRIGGERED_LABEL,
  [STATUS_ACKNOWLEDGED]: STATUS_ACKNOWLEDGED_LABEL,
  [STATUS_RESOLVED]: STATUS_RESOLVED_LABEL,
};

export const i18n = {
  fetchError: s__(
    'IncidentManagement|An error occurred while fetching the incident status. Please reload the page.',
  ),
  title: s__('IncidentManagement|Status'),
  updateError: s__(
    'IncidentManagement|An error occurred while updating the incident status. Please reload the page and try again.',
  ),
};
