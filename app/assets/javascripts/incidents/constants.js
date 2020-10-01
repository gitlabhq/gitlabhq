import { s__, __ } from '~/locale';

export const I18N = {
  errorMsg: s__('IncidentManagement|There was an error displaying the incidents.'),
  noIncidents: s__('IncidentManagement|No incidents to display.'),
  unassigned: s__('IncidentManagement|Unassigned'),
  createIncidentBtnLabel: s__('IncidentManagement|Create incident'),
  unPublished: s__('IncidentManagement|Unpublished'),
  searchPlaceholder: __('Search or filter results…'),
  emptyState: {
    title: s__('IncidentManagement|Display your incidents in a dedicated view'),
    emptyClosedTabTitle: s__('IncidentManagement|There are no closed incidents'),
    description: s__(
      'IncidentManagement|All alerts promoted to incidents will automatically be displayed within the list. You can also create a new incident using the button below.',
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

export const DEFAULT_PAGE_SIZE = 20;
export const TH_CREATED_AT_TEST_ID = { 'data-testid': 'incident-management-created-at-sort' };
export const TH_SEVERITY_TEST_ID = { 'data-testid': 'incident-management-severity-sort' };
export const TH_PUBLISHED_TEST_ID = { 'data-testid': 'incident-management-published-sort' };
export const INCIDENT_DETAILS_PATH = 'incident';
