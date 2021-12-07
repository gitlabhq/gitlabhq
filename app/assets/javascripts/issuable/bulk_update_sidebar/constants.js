import { __ } from '~/locale';

export const ISSUE_STATUS_MODIFIERS = {
  REOPEN: 'reopen',
  CLOSE: 'close',
};

export const ISSUE_STATUS_SELECT_OPTIONS = [
  {
    value: ISSUE_STATUS_MODIFIERS.REOPEN,
    text: __('Open'),
  },
  {
    value: ISSUE_STATUS_MODIFIERS.CLOSE,
    text: __('Closed'),
  },
];
