import AccessorUtilities from '~/lib/utils/accessor';
import { LOCAL_STORAGE_ALERT_KEY } from './constants';

export const saveAlertToLocalStorage = (alertOptions) => {
  if (AccessorUtilities.canUseLocalStorage()) {
    localStorage.setItem(LOCAL_STORAGE_ALERT_KEY, JSON.stringify(alertOptions));
  }
};
