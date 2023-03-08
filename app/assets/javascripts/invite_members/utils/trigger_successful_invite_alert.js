import { createAlert } from '~/alert';
import AccessorUtilities from '~/lib/utils/accessor';

import { TOAST_MESSAGE_LOCALSTORAGE_KEY, TOAST_MESSAGE_SUCCESSFUL } from '../constants';

export function displaySuccessfulInvitationAlert() {
  if (!AccessorUtilities.canUseLocalStorage()) {
    return;
  }

  const showAlert = Boolean(localStorage.getItem(TOAST_MESSAGE_LOCALSTORAGE_KEY));
  if (showAlert) {
    localStorage.removeItem(TOAST_MESSAGE_LOCALSTORAGE_KEY);
    createAlert({ message: TOAST_MESSAGE_SUCCESSFUL, variant: 'info' });
  }
}

export function reloadOnInvitationSuccess() {
  if (AccessorUtilities.canUseLocalStorage()) {
    localStorage.setItem(TOAST_MESSAGE_LOCALSTORAGE_KEY, 'true');
  }
  window.location.reload();
}
