import { createAlert } from '~/alert';
import AccessorUtilities from '~/lib/utils/accessor';

import {
  TOAST_MESSAGE_LOCALSTORAGE_KEY,
  MEMBERS_WITH_QUEUED_STATUS_LOCALSTORAGE_KEY,
  TOAST_MESSAGE_SUCCESSFUL,
  QUEUED_MESSAGE_SUCCESSFUL,
} from '../constants';

export function displaySuccessfulInvitationAlert() {
  if (!AccessorUtilities.canUseLocalStorage()) {
    return;
  }

  const messages = [];

  const appendSuccessfulMessage = Boolean(localStorage.getItem(TOAST_MESSAGE_LOCALSTORAGE_KEY));
  if (appendSuccessfulMessage) {
    localStorage.removeItem(TOAST_MESSAGE_LOCALSTORAGE_KEY);
    messages.push(TOAST_MESSAGE_SUCCESSFUL);
  }
  const appendQueuedMessage = Boolean(
    localStorage.getItem(MEMBERS_WITH_QUEUED_STATUS_LOCALSTORAGE_KEY),
  );
  if (appendQueuedMessage) {
    localStorage.removeItem(MEMBERS_WITH_QUEUED_STATUS_LOCALSTORAGE_KEY);
    messages.push(QUEUED_MESSAGE_SUCCESSFUL);
  }

  if (messages.length) {
    createAlert({ message: messages.join(' '), variant: 'info' });
  }
}

export function reloadOnInvitationSuccess() {
  if (AccessorUtilities.canUseLocalStorage()) {
    localStorage.setItem(TOAST_MESSAGE_LOCALSTORAGE_KEY, 'true');
  }
  window.location.reload();
}

export function markLocalStorageForQueuedAlert() {
  if (AccessorUtilities.canUseLocalStorage()) {
    localStorage.setItem(MEMBERS_WITH_QUEUED_STATUS_LOCALSTORAGE_KEY, 'true');
  }
  window.location.reload();
}
