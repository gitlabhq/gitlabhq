import { __ } from '~/locale';

export const IssueStateEvent = {
  Close: 'CLOSE',
  Reopen: 'REOPEN',
};

export const STATUS_PAGE_PUBLISHED = __('Published on status page');
export const JOIN_ZOOM_MEETING = __('Join Zoom meeting');

export const IssuableTypes = [
  { value: 'issue', text: __('Issue'), icon: 'issue-type-issue' },
  { value: 'incident', text: __('Incident'), icon: 'issue-type-incident' },
];

export const IssueTypePath = 'issues';
export const IncidentTypePath = 'issues/incident';
export const IncidentType = 'incident';

export const issueState = { issueType: undefined, isDirty: false };

export const POLLING_DELAY = 2000;
