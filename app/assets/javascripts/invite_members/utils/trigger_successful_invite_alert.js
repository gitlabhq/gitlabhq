import { createAlert } from '~/alert';
import AccessorUtilities from '~/lib/utils/accessor';

import {
  MEMBER_INVITE_LOCALSTORAGE_KEY,
  MEMBER_INVITE_MESSAGE_SUCCESSFUL,
  GROUP_INVITE_LOCALSTORAGE_KEY,
  GROUP_INVITE_MESSAGE_SUCCESSFUL,
  MEMBERS_WITH_QUEUED_STATUS_LOCALSTORAGE_KEY,
  QUEUED_MESSAGE_SUCCESSFUL,
} from '../constants';

export function displaySuccessfulInvitationAlert() {
  if (!AccessorUtilities.canUseLocalStorage()) {
    return;
  }

  const messages = [];
  const successMessages = {
    [MEMBER_INVITE_LOCALSTORAGE_KEY]: MEMBER_INVITE_MESSAGE_SUCCESSFUL,
    [GROUP_INVITE_LOCALSTORAGE_KEY]: GROUP_INVITE_MESSAGE_SUCCESSFUL,
    [MEMBERS_WITH_QUEUED_STATUS_LOCALSTORAGE_KEY]: QUEUED_MESSAGE_SUCCESSFUL,
  };

  for (const [localStorageKey, successMessage] of Object.entries(successMessages)) {
    if (localStorage.getItem(localStorageKey)) {
      localStorage.removeItem(localStorageKey);
      messages.push(successMessage);
    }
  }

  if (messages.length) {
    createAlert({ message: messages.join(' '), variant: 'info' });
  }
}

export function reloadOnMemberInvitationSuccess() {
  if (AccessorUtilities.canUseLocalStorage()) {
    localStorage.setItem(MEMBER_INVITE_LOCALSTORAGE_KEY, 'true');
  }
  window.location.reload();
}

export function reloadOnGroupInvitationSuccess() {
  if (AccessorUtilities.canUseLocalStorage()) {
    localStorage.setItem(GROUP_INVITE_LOCALSTORAGE_KEY, 'true');
  }
  window.location.reload();
}

export function markLocalStorageForQueuedAlert() {
  if (AccessorUtilities.canUseLocalStorage()) {
    localStorage.setItem(MEMBERS_WITH_QUEUED_STATUS_LOCALSTORAGE_KEY, 'true');
  }
  window.location.reload();
}
