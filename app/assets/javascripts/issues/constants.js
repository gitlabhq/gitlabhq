import { __ } from '~/locale';

export const STATUS_CLOSED = 'closed';
export const STATUS_OPEN = 'opened';
export const STATUS_REOPENED = 'reopened';

export const TITLE_LENGTH_MAX = 255;

export const IssuableStatusText = {
  [STATUS_CLOSED]: __('Closed'),
  [STATUS_OPEN]: __('Open'),
  [STATUS_REOPENED]: __('Open'),
};

export const IssuableType = {
  Issue: 'issue',
  Epic: 'epic',
  MergeRequest: 'merge_request',
  Alert: 'alert',
  TestCase: 'test_case',
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
