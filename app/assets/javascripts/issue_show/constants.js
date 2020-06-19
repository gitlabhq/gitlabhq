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

export const STATUS_PAGE_PUBLISHED = __('Published on status page');
export const JOIN_ZOOM_MEETING = __('Join Zoom meeting');
