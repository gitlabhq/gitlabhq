import { __ } from '~/locale';

export const i18n = {
  closed: __('Closed'),
  merged: __('Merged'),
  yes: __('Yes'),
  no: __('No'),
  errorFetchingBranches: __('Failed to load branches. Please try again.'),
  errorFetchingCounts: __('An error occurred while getting merge request counts'),
  errorFetchingMergeRequests: __('An error occurred while loading merge requests'),
  upvotes: __('Upvotes'),
  downvots: __('Downvotes'),
  newMergeRequest: __('New merge request'),
};

export const BRANCH_LIST_REFRESH_INTERVAL = 600000; // 10 minutes (* 60 seconds, * 1000 milliseconds)
