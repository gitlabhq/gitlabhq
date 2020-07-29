import { s__, __ } from '~/locale';

export const I18N = {
  errorMsg: s__('IncidentManagement|There was an error displaying the incidents.'),
  noIncidents: s__('IncidentManagement|No incidents to display.'),
  unassigned: s__('IncidentManagement|Unassigned'),
  createIncidentBtnLabel: s__('IncidentManagement|Create incident'),
  searchPlaceholder: __('Search or filter results...'),
};

export const INCIDENT_SEARCH_DELAY = 300;
export const DEFAULT_PAGE_SIZE = 10;
