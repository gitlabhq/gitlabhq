import { timeRanges } from '~/vue_shared/constants';
import { __ } from '~/locale';

export const NEVER_TIME_RANGE = {
  label: __('Never'),
  name: 'never',
};

export const TIME_RANGES_WITH_NEVER = [NEVER_TIME_RANGE, ...timeRanges];

export const AVAILABILITY_STATUS = {
  BUSY: 'busy',
  NOT_SET: 'not_set',
};

export const SET_STATUS_MODAL_ID = 'set-user-status-modal';
