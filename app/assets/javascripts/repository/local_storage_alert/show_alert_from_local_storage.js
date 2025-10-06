import AccessorUtilities from '~/lib/utils/accessor';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { LOCAL_STORAGE_ALERT_KEY } from './constants';

export const showAlertFromLocalStorage = async () => {
  if (AccessorUtilities.canUseLocalStorage()) {
    const alertOptions = localStorage.getItem(LOCAL_STORAGE_ALERT_KEY);

    if (alertOptions) {
      try {
        const { createAlert } = await import('~/alert');
        createAlert(JSON.parse(alertOptions));
      } catch (error) {
        Sentry.captureException(error);
      }
    }
    localStorage.removeItem(LOCAL_STORAGE_ALERT_KEY);
  }
};
