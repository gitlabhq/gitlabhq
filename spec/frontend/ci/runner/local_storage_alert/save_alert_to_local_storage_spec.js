import AccessorUtilities from '~/lib/utils/accessor';
import { saveAlertToLocalStorage } from '~/ci/runner/local_storage_alert/save_alert_to_local_storage';
import { LOCAL_STORAGE_ALERT_KEY } from '~/ci/runner/local_storage_alert/constants';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';

const mockAlert = { message: 'Message!' };

describe('saveAlertToLocalStorage', () => {
  useLocalStorageSpy();

  beforeEach(() => {
    jest.spyOn(AccessorUtilities, 'canUseLocalStorage').mockReturnValue(true);
  });

  it('saves message to local storage', () => {
    saveAlertToLocalStorage(mockAlert);

    expect(localStorage.setItem).toHaveBeenCalledTimes(1);
    expect(localStorage.setItem).toHaveBeenCalledWith(
      LOCAL_STORAGE_ALERT_KEY,
      JSON.stringify(mockAlert),
    );
  });
});
