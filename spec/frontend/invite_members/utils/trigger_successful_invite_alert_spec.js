import {
  displaySuccessfulInvitationAlert,
  markLocalStorageForQueuedAlert,
  reloadOnMemberInvitationSuccess,
  reloadOnGroupInvitationSuccess,
} from '~/invite_members/utils/trigger_successful_invite_alert';
import {
  MEMBERS_WITH_QUEUED_STATUS_LOCALSTORAGE_KEY,
  QUEUED_MESSAGE_SUCCESSFUL,
  MEMBER_INVITE_LOCALSTORAGE_KEY,
  GROUP_INVITE_LOCALSTORAGE_KEY,
  MEMBER_INVITE_MESSAGE_SUCCESSFUL,
  GROUP_INVITE_MESSAGE_SUCCESSFUL,
} from '~/invite_members/constants';
import { createAlert } from '~/alert';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';

jest.mock('~/alert');
useLocalStorageSpy();

describe('Display Successful Invitation Alert', () => {
  it('does not show an alert if localStorage key not present', () => {
    localStorage.removeItem(MEMBER_INVITE_LOCALSTORAGE_KEY);

    displaySuccessfulInvitationAlert();

    expect(createAlert).not.toHaveBeenCalled();
  });

  it('shows an alert with successful message member invite key is present in localStorage', () => {
    localStorage.setItem(MEMBER_INVITE_LOCALSTORAGE_KEY, 'true');

    displaySuccessfulInvitationAlert();

    expect(createAlert).toHaveBeenCalledWith({
      message: MEMBER_INVITE_MESSAGE_SUCCESSFUL,
      variant: 'info',
    });
  });

  it('shows an alert with successful message group invite key is present in localStorage', () => {
    localStorage.setItem(GROUP_INVITE_LOCALSTORAGE_KEY, 'true');

    displaySuccessfulInvitationAlert();

    expect(createAlert).toHaveBeenCalledWith({
      message: GROUP_INVITE_MESSAGE_SUCCESSFUL,
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
    localStorage.setItem(MEMBER_INVITE_LOCALSTORAGE_KEY, 'true');
    localStorage.setItem(MEMBERS_WITH_QUEUED_STATUS_LOCALSTORAGE_KEY, 'true');
    displaySuccessfulInvitationAlert();

    expect(createAlert).toHaveBeenCalledWith({
      message: `${MEMBER_INVITE_MESSAGE_SUCCESSFUL} ${QUEUED_MESSAGE_SUCCESSFUL}`,
      variant: 'info',
    });
  });
});

describe('Reload On Member Invitation Success', () => {
  beforeAll(() => {
    useMockLocationHelper();
  });

  it('sets localStorage value', () => {
    reloadOnMemberInvitationSuccess();

    expect(localStorage.setItem).toHaveBeenCalledWith(MEMBER_INVITE_LOCALSTORAGE_KEY, 'true');
  });

  it('calls window.location.reload', () => {
    reloadOnMemberInvitationSuccess();

    expect(window.location.reload).toHaveBeenCalled();
  });
});

describe('Reload On Group Invitation Success', () => {
  beforeAll(() => {
    useMockLocationHelper();
  });

  it('sets localStorage value', () => {
    reloadOnGroupInvitationSuccess();

    expect(localStorage.setItem).toHaveBeenCalledWith(GROUP_INVITE_LOCALSTORAGE_KEY, 'true');
  });

  it('calls window.location.reload', () => {
    reloadOnGroupInvitationSuccess();

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
