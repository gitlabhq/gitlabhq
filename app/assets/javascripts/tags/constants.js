import { s__ } from '~/locale';

export const MODAL_TITLE = s__('TagsPage|Permanently delete tag?');

export const MODAL_TITLE_PROTECTED_TAG = s__('TagsPage|Permanently delete protected tag?');

export const MODAL_MESSAGE = s__(
  'TagsPage|Deleting the %{strongStart}%{tagName}%{strongEnd} tag cannot be undone.',
);

export const MODAL_MESSAGE_PROTECTED_TAG = s__(
  'TagsPage|Deleting the %{strongStart}%{tagName}%{strongEnd} protected tag cannot be undone.',
);

export const CANCEL_BUTTON_TEXT = s__('TagsPage|Cancel, keep tag');

export const CONFIRMATION_TEXT = s__('TagsPage|Are you sure you want to delete this tag?');

export const CONFIRMATION_TEXT_PROTECTED_TAG = s__(
  'TagsPage|Please type the following to confirm:',
);

export const DELETE_BUTTON_TEXT = s__('TagsPage|Yes, delete tag');

export const DELETE_BUTTON_TEXT_PROTECTED_TAG = s__('TagsPage|Yes, delete protected tag');

export const I18N_DELETE_TAG_MODAL = {
  modalTitle: MODAL_TITLE,
  modalTitleProtectedTag: MODAL_TITLE_PROTECTED_TAG,
  modalMessage: MODAL_MESSAGE,
  modalMessageProtectedTag: MODAL_MESSAGE_PROTECTED_TAG,
  cancelButtonText: CANCEL_BUTTON_TEXT,
  confirmationText: CONFIRMATION_TEXT,
  confirmationTextProtectedTag: CONFIRMATION_TEXT_PROTECTED_TAG,
  deleteButtonText: DELETE_BUTTON_TEXT,
  deleteButtonTextProtectedTag: DELETE_BUTTON_TEXT_PROTECTED_TAG,
};
