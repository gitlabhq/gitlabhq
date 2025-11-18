import AccessorUtilities from '~/lib/utils/accessor';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { showAlertFromLocalStorage } from '~/lib/utils/local_storage_alert/show_alert_from_local_storage';
import { LOCAL_STORAGE_ALERT_KEY } from '~/lib/utils/local_storage_alert/constants';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import { createAlert } from '~/alert';

jest.mock('~/alert');
jest.mock('~/sentry/sentry_browser_wrapper');

describe('showAlertFromLocalStorage', () => {
  useLocalStorageSpy();

  beforeEach(() => {
    jest.spyOn(AccessorUtilities, 'canUseLocalStorage').mockReturnValue(true);
  });

  it('retrieves message from local storage and displays it', async () => {
    const mockAlert = { message: 'Message!' };

    localStorage.getItem.mockReturnValueOnce(JSON.stringify(mockAlert));

    await showAlertFromLocalStorage();

    expect(localStorage.getItem).toHaveBeenCalledWith(LOCAL_STORAGE_ALERT_KEY);
    expect(createAlert).toHaveBeenCalledTimes(1);
    expect(createAlert).toHaveBeenCalledWith(mockAlert);

    expect(localStorage.removeItem).toHaveBeenCalledTimes(1);
    expect(localStorage.removeItem).toHaveBeenCalledWith(LOCAL_STORAGE_ALERT_KEY);
  });

  it('retrieves complex alert options from local storage and displays them', async () => {
    const complexAlert = {
      message: 'Your changes have been committed successfully.',
      variant: 'success',
      renderMessageHTML: true,
    };

    localStorage.getItem.mockReturnValueOnce(JSON.stringify(complexAlert));

    await showAlertFromLocalStorage();

    expect(createAlert).toHaveBeenCalledTimes(1);
    expect(createAlert).toHaveBeenCalledWith(complexAlert);

    expect(localStorage.removeItem).toHaveBeenCalledTimes(1);
    expect(localStorage.removeItem).toHaveBeenCalledWith(LOCAL_STORAGE_ALERT_KEY);
  });

  it.each(['not a json string', null])('does not fail when stored message is %o', async (item) => {
    localStorage.getItem.mockReturnValueOnce(item);

    await showAlertFromLocalStorage();

    expect(createAlert).not.toHaveBeenCalled();

    expect(localStorage.removeItem).toHaveBeenCalledTimes(1);
    expect(localStorage.removeItem).toHaveBeenCalledWith(LOCAL_STORAGE_ALERT_KEY);
  });

  it('does not show alert when localStorage is not available', async () => {
    jest.spyOn(AccessorUtilities, 'canUseLocalStorage').mockReturnValue(false);

    await showAlertFromLocalStorage();

    expect(localStorage.getItem).not.toHaveBeenCalled();
    expect(createAlert).not.toHaveBeenCalled();
    expect(localStorage.removeItem).not.toHaveBeenCalled();
  });

  it('removes item from localStorage even when no alert is stored', async () => {
    localStorage.getItem.mockReturnValueOnce(null);

    await showAlertFromLocalStorage();

    expect(createAlert).not.toHaveBeenCalled();
    expect(localStorage.removeItem).toHaveBeenCalledTimes(1);
    expect(localStorage.removeItem).toHaveBeenCalledWith(LOCAL_STORAGE_ALERT_KEY);
  });

  it('handles JSON parsing errors gracefully and logs error to Sentry by default', async () => {
    localStorage.getItem.mockReturnValueOnce('invalid json {');

    await showAlertFromLocalStorage();

    expect(createAlert).not.toHaveBeenCalled();
    expect(localStorage.removeItem).toHaveBeenCalledTimes(1);
    expect(localStorage.removeItem).toHaveBeenCalledWith(LOCAL_STORAGE_ALERT_KEY);
    expect(Sentry.captureException).toHaveBeenCalledWith(expect.any(Error));
  });
});
