import {
  displaySuccessfulInvitationAlert,
  markLocalStorageForQueuedAlert,
  reloadOnInvitationSuccess,
} from '~/invite_members/utils/trigger_successful_invite_alert';
import {
  MEMBERS_WITH_QUEUED_STATUS_LOCALSTORAGE_KEY,
  QUEUED_MESSAGE_SUCCESSFUL,
  TOAST_MESSAGE_LOCALSTORAGE_KEY,
  TOAST_MESSAGE_SUCCESSFUL,
} from '~/invite_members/constants';
import { createAlert } from '~/alert';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';

jest.mock('~/alert');
useLocalStorageSpy();

describe('Display Successful Invitation Alert', () => {
  it('does not show an alert if localStorage key not present', () => {
    localStorage.removeItem(TOAST_MESSAGE_LOCALSTORAGE_KEY);

    displaySuccessfulInvitationAlert();

    expect(createAlert).not.toHaveBeenCalled();
  });

  it('shows an alert with successful message when localStorage success key is present', () => {
    localStorage.setItem(TOAST_MESSAGE_LOCALSTORAGE_KEY, 'true');

    displaySuccessfulInvitationAlert();

    expect(createAlert).toHaveBeenCalledWith({
      message: TOAST_MESSAGE_SUCCESSFUL,
      variant: 'info',
    });
  });

  it('shows an alert with queued message when localStorage queued key is present', () => {
    localStorage.setItem(MEMBERS_WITH_QUEUED_STATUS_LOCALSTORAGE_KEY, 'true');

    displaySuccessfulInvitationAlert();

    expect(createAlert).toHaveBeenCalledWith({
      message: QUEUED_MESSAGE_SUCCESSFUL,
      variant: 'info',
    });
  });

  it('shows an alert with both successful and queued mesages localStorage has both keys', () => {
    localStorage.setItem(TOAST_MESSAGE_LOCALSTORAGE_KEY, 'true');
    localStorage.setItem(MEMBERS_WITH_QUEUED_STATUS_LOCALSTORAGE_KEY, 'true');
    displaySuccessfulInvitationAlert();

    expect(createAlert).toHaveBeenCalledWith({
      message: `${TOAST_MESSAGE_SUCCESSFUL} ${QUEUED_MESSAGE_SUCCESSFUL}`,
      variant: 'info',
    });
  });
});

describe('Reload On Invitation Success', () => {
  beforeAll(() => {
    useMockLocationHelper();
  });

  it('sets localStorage value', () => {
    reloadOnInvitationSuccess();

    expect(localStorage.setItem).toHaveBeenCalledWith(TOAST_MESSAGE_LOCALSTORAGE_KEY, 'true');
  });

  it('calls window.location.reload', () => {
    reloadOnInvitationSuccess();

    expect(window.location.reload).toHaveBeenCalled();
  });
});

describe('markLocalStorageForQueuedAlert', () => {
  beforeAll(() => {
    useMockLocationHelper();
  });

  it('sets localStorage value', () => {
    markLocalStorageForQueuedAlert();

    expect(localStorage.setItem).toHaveBeenCalledWith(
      MEMBERS_WITH_QUEUED_STATUS_LOCALSTORAGE_KEY,
      'true',
    );
  });

  it('calls window.location.reload', () => {
    markLocalStorageForQueuedAlert();

    expect(window.location.reload).toHaveBeenCalled();
  });
});
