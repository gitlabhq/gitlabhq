import { __ } from '~/locale';

export const IssuableStatus = {
  Open: 'opened',
  Closed: 'closed',
};

export const IssuableStatusText = {
  [IssuableStatus.Open]: __('Open'),
  [IssuableStatus.Closed]: __('Closed'),
};

export const IssuableType = {
  Issue: 'issue',
  Epic: 'epic',
  MergeRequest: 'merge_request',
};
