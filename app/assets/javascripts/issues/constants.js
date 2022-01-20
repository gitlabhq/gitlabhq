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

export const IssueType = {
  Issue: 'issue',
  Incident: 'incident',
  TestCase: 'test_case',
};

export const WorkspaceType = {
  project: 'project',
  group: 'group',
};
