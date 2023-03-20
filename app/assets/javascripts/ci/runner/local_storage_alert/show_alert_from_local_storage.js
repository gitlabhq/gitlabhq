import AccessorUtilities from '~/lib/utils/accessor';
import { LOCAL_STORAGE_ALERT_KEY } from './constants';

export const showAlertFromLocalStorage = async () => {
  if (AccessorUtilities.canUseLocalStorage()) {
    const alertOptions = localStorage.getItem(LOCAL_STORAGE_ALERT_KEY);

    if (alertOptions) {
      try {
        const { createAlert } = await import('~/alert');
        createAlert(JSON.parse(alertOptions));
      } catch {
        // ignore when the alert data cannot be parsed
      }
    }
    localStorage.removeItem(LOCAL_STORAGE_ALERT_KEY);
  }
};
