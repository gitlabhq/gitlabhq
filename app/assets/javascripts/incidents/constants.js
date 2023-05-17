import { s__ } from '~/locale';

export const I18N = {
  errorMsg: s__('IncidentManagement|There was an error displaying the incidents.'),
  noIncidents: s__('IncidentManagement|No incidents to display.'),
  unassigned: s__('IncidentManagement|Unassigned'),
  createIncidentBtnLabel: s__('IncidentManagement|Create incident'),
  unPublished: s__('IncidentManagement|Unpublished'),
  noEscalationStatus: s__('IncidentManagement|None'),
  emptyState: {
    title: s__('IncidentManagement|Display your incidents in a dedicated view'),
    emptyClosedTabTitle: s__('IncidentManagement|There are no closed incidents'),
    description: s__(
      'IncidentManagement|All alerts promoted to incidents are automatically displayed within the list. You can also create a new incident using the button below.',
    ),
    cannotCreateIncidentDescription: s__(
      'IncidentManagement|All alerts promoted to incidents are automatically displayed within the list.',
    ),
  },
};

export const INCIDENT_STATUS_TABS = [
  {
    title: s__('IncidentManagement|Open'),
    status: 'OPENED',
    filters: 'opened',
  },
  {
    title: s__('IncidentManagement|Closed'),
    status: 'CLOSED',
    filters: 'closed',
  },
  {
    title: s__('IncidentManagement|All'),
    status: 'ALL',
    filters: 'all',
  },
];

export const ESCALATION_STATUSES = {
  TRIGGERED: s__('AlertManagement|Triggered'),
  ACKNOWLEDGED: s__('AlertManagement|Acknowledged'),
  RESOLVED: s__('AlertManagement|Resolved'),
};

export const TH_CREATED_AT_TEST_ID = { 'data-testid': 'incident-management-created-at-sort' };
export const TH_SEVERITY_TEST_ID = { 'data-testid': 'incident-management-severity-sort' };
export const TH_ESCALATION_STATUS_TEST_ID = { 'data-testid': 'incident-management-status-sort' };
export const TH_INCIDENT_SLA_TEST_ID = { 'data-testid': 'incident-management-sla' };
export const TH_PUBLISHED_TEST_ID = { 'data-testid': 'incident-management-published-sort' };
export const INCIDENT_DETAILS_PATH = 'incident';

const category = 'Incident Management'; // eslint-disable-line @gitlab/require-i18n-strings

/**
 * Tracks snowplow event when user clicks create new incident
 */
export const trackIncidentCreateNewOptions = {
  category,
  action: 'create_incident_button_clicks',
};

/**
 * Tracks snowplow event when user views incidents list
 */
export const trackIncidentListViewsOptions = {
  category,
  action: 'view_incidents_list',
};

/**
 * Tracks snowplow event when user views incident details
 */
export const trackIncidentDetailsViewsOptions = {
  category,
  action: 'view_incident_details',
};
