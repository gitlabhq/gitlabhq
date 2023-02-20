import { __ } from '~/locale';

export const RESOURCE_TYPE_ISSUE = 'issue';
export const RESOURCE_TYPE_MERGE_REQUEST = 'merge-request';
export const RESOURCE_TYPE_MILESTONE = 'milestone';

export const RESOURCE_TYPES = [
  RESOURCE_TYPE_ISSUE,
  RESOURCE_TYPE_MERGE_REQUEST,
  RESOURCE_TYPE_MILESTONE,
];

export const RESOURCE_OPTIONS = {
  [RESOURCE_TYPE_ISSUE]: {
    path: 'issues/new',
    label: __('issue'),
  },
  [RESOURCE_TYPE_MERGE_REQUEST]: {
    path: 'merge_requests/new',
    label: __('merge request'),
  },
  [RESOURCE_TYPE_MILESTONE]: {
    path: 'milestones/new',
    label: __('milestone'),
  },
};
