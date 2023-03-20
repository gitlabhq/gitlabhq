import AccessorUtilities from '~/lib/utils/accessor';
import { showAlertFromLocalStorage } from '~/ci/runner/local_storage_alert/show_alert_from_local_storage';
import { LOCAL_STORAGE_ALERT_KEY } from '~/ci/runner/local_storage_alert/constants';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import { createAlert } from '~/alert';

jest.mock('~/alert');

describe('showAlertFromLocalStorage', () => {
  useLocalStorageSpy();

  beforeEach(() => {
    jest.spyOn(AccessorUtilities, 'canUseLocalStorage').mockReturnValue(true);
  });

  it('retrieves message from local storage and displays it', async () => {
    const mockAlert = { message: 'Message!' };

    localStorage.getItem.mockReturnValueOnce(JSON.stringify(mockAlert));

    await showAlertFromLocalStorage();

    expect(createAlert).toHaveBeenCalledTimes(1);
    expect(createAlert).toHaveBeenCalledWith(mockAlert);

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
});
