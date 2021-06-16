import { __ } from '~/locale';

export const IssuableStatus = {
  Closed: 'closed',
  Open: 'opened',
  Reopened: 'reopened',
};

export const IssuableStatusText = {
  [IssuableStatus.Closed]: __('Closed'),
  [IssuableStatus.Open]: __('Open'),
  [IssuableStatus.Reopened]: __('Open'),
};

export const IssuableType = {
  Issue: 'issue',
  Epic: 'epic',
  MergeRequest: 'merge_request',
  Alert: 'alert',
};

export const IssueStateEvent = {
  Close: 'CLOSE',
  Reopen: 'REOPEN',
};

export const STATUS_PAGE_PUBLISHED = __('Published on status page');
export const JOIN_ZOOM_MEETING = __('Join Zoom meeting');

export const IssuableTypes = [
  { value: 'issue', text: __('Issue') },
  { value: 'incident', text: __('Incident') },
];

export const IssueTypePath = 'issues';
export const IncidentTypePath = 'issues/incident';
export const IncidentType = 'incident';

export const issueState = { issueType: undefined, isDirty: false };
