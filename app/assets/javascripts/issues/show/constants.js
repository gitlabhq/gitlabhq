import { __ } from '~/locale';

export const INCIDENT_TYPE_PATH = 'issues/incident';
export const ISSUE_STATE_EVENT_CLOSE = 'CLOSE';
export const ISSUE_STATE_EVENT_REOPEN = 'REOPEN';
export const ISSUE_TYPE_PATH = 'issues';
export const JOIN_ZOOM_MEETING = __('Join Zoom meeting');
export const POLLING_DELAY = 2000;
export const STATUS_PAGE_PUBLISHED = __('Published on status page');

export const issuableTypes = [
  { value: 'issue', text: __('Issue'), icon: 'issue-type-issue' },
  { value: 'incident', text: __('Incident'), icon: 'issue-type-incident' },
];

export const issueState = {
  issueType: undefined,
  isDirty: false,
};
