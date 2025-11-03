import AccessorUtilities from '~/lib/utils/accessor';
import { saveAlertToLocalStorage } from '~/lib/utils/local_storage_alert/save_alert_to_local_storage';
import { LOCAL_STORAGE_ALERT_KEY } from '~/lib/utils/local_storage_alert/constants';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';

const mockAlert = { message: 'Message!' };

describe('saveAlertToLocalStorage', () => {
  useLocalStorageSpy();

  beforeEach(() => {
    jest.spyOn(AccessorUtilities, 'canUseLocalStorage').mockReturnValue(true);
  });

  it('saves message to local storage with provided key', () => {
    saveAlertToLocalStorage(mockAlert);

    expect(localStorage.setItem).toHaveBeenCalledTimes(1);
    expect(localStorage.setItem).toHaveBeenCalledWith(
      LOCAL_STORAGE_ALERT_KEY,
      JSON.stringify(mockAlert),
    );
  });

  it('does not save to local storage when localStorage is not available', () => {
    jest.spyOn(AccessorUtilities, 'canUseLocalStorage').mockReturnValue(false);

    saveAlertToLocalStorage(mockAlert);

    expect(localStorage.setItem).not.toHaveBeenCalled();
  });

  it('saves complex alert options to local storage', () => {
    const complexAlert = {
      message: 'Your changes have been committed successfully.',
      variant: 'success',
      renderMessageHTML: true,
    };

    saveAlertToLocalStorage(complexAlert);

    expect(localStorage.setItem).toHaveBeenCalledTimes(1);
    expect(localStorage.setItem).toHaveBeenCalledWith(
      LOCAL_STORAGE_ALERT_KEY,
      JSON.stringify(complexAlert),
    );
  });
});
