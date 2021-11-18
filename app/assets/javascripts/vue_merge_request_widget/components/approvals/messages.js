import { __, s__ } from '~/locale';

export const FETCH_LOADING = __('Checking approval status');
export const FETCH_ERROR = s__(
  'mrWidget|An error occurred while retrieving approval data for this merge request.',
);
export const APPROVE_ERROR = s__('mrWidget|An error occurred while submitting your approval.');
export const UNAPPROVE_ERROR = s__('mrWidget|An error occurred while removing your approval.');
export const APPROVED_BY_YOU_AND_OTHERS = s__('mrWidget|Approved by you and others');
export const APPROVED_BY_YOU = s__('mrWidget|Approved by you');
export const APPROVED_BY_OTHERS = s__('mrWidget|Approved by');
