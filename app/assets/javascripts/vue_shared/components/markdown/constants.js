import { __ } from '~/locale';

export const TRACKING_SAVED_REPLIES_USE = 'i_code_review_saved_replies_use';
export const TRACKING_SAVED_REPLIES_USE_IN_MR = 'i_code_review_saved_replies_use_in_mr';
export const TRACKING_SAVED_REPLIES_USE_IN_OTHER = 'i_code_review_saved_replies_use_in_other';

export const COMMENT_TEMPLATES_KEYS = ['currentUser'];
export const COMMENT_TEMPLATES_TITLES = { currentUser: __('User') };

// Selects all focusable elements currently present in the find-and-replace dialog.
// If new focusable element types are added to the dialog, update this selector accordingly.
export const FIND_AND_REPLACE_FOCUSABLE_SELECTOR =
  'button:not([disabled]), input:not([disabled]), [tabindex]:not([tabindex="-1"])';

export const RESTRICTED_TOOLBAR_ITEMS_BASIC_EDITING_ONLY = [
  'code',
  'quote',
  'bullet-list',
  'numbered-list',
  'task-list',
  'collapsible-section',
  'table',
  'attach-file',
  'full-screen',
];
