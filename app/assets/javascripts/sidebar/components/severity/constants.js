import { __, s__ } from '~/locale';

export const INCIDENT_SEVERITY = {
  CRITICAL: {
    value: 'CRITICAL',
    icon: 'critical',
    label: s__('IncidentManagement|Critical - S1'),
  },
  HIGH: {
    value: 'HIGH',
    icon: 'high',
    label: s__('IncidentManagement|High - S2'),
  },
  MEDIUM: {
    value: 'MEDIUM',
    icon: 'medium',
    label: s__('IncidentManagement|Medium - S3'),
  },
  LOW: {
    value: 'LOW',
    icon: 'low',
    label: s__('IncidentManagement|Low - S4'),
  },
  UNKNOWN: {
    value: 'UNKNOWN',
    icon: 'unknown',
    label: s__('IncidentManagement|Unknown'),
  },
};

export const ISSUABLE_TYPES = {
  INCIDENT: 'incident',
};

export const I18N = {
  UPDATE_SEVERITY_ERROR: s__('SeverityWidget|There was an error while updating severity.'),
  TRY_AGAIN: __('Please try again'),
  EDIT: __('Edit'),
  SEVERITY: s__('SeverityWidget|Severity'),
  SEVERITY_VALUE: s__('SeverityWidget|Severity: %{severity}'),
};
