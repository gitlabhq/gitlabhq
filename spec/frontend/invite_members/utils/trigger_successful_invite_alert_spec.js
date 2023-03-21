import {
  displaySuccessfulInvitationAlert,
  reloadOnInvitationSuccess,
} from '~/invite_members/utils/trigger_successful_invite_alert';
import {
  TOAST_MESSAGE_LOCALSTORAGE_KEY,
  TOAST_MESSAGE_SUCCESSFUL,
} from '~/invite_members/constants';
import { createAlert } from '~/alert';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';

jest.mock('~/alert');
useLocalStorageSpy();

describe('Display Successful Invitation Alert', () => {
  it('does not show an alert if localStorage key not present', () => {
    localStorage.removeItem(TOAST_MESSAGE_LOCALSTORAGE_KEY);

    displaySuccessfulInvitationAlert();

    expect(createAlert).not.toHaveBeenCalled();
  });

  it('shows an alert when localStorage key is present', () => {
    localStorage.setItem(TOAST_MESSAGE_LOCALSTORAGE_KEY, 'true');

    displaySuccessfulInvitationAlert();

    expect(createAlert).toHaveBeenCalledWith({
      message: TOAST_MESSAGE_SUCCESSFUL,
      variant: 'info',
    });
  });
});

describe('Reload On Invitation Success', () => {
  const { location } = window;

  beforeAll(() => {
    delete window.location;
    window.location = { reload: jest.fn() };
  });

  afterAll(() => {
    window.location = location;
  });

  it('sets localStorage value and calls window.location.reload', () => {
    reloadOnInvitationSuccess();

    expect(localStorage.setItem).toHaveBeenCalledWith(TOAST_MESSAGE_LOCALSTORAGE_KEY, 'true');
    expect(window.location.reload).toHaveBeenCalled();
  });
});
