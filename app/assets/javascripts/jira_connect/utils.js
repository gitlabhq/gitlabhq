import AccessorUtilities from '~/lib/utils/accessor';
import { ALERT_LOCALSTORAGE_KEY } from './constants';

const isFunction = (fn) => typeof fn === 'function';

/**
 * Persist alert data to localStorage.
 */
export const persistAlert = ({ title, message, linkUrl, variant } = {}) => {
  if (!AccessorUtilities.isLocalStorageAccessSafe()) {
    return;
  }

  const payload = JSON.stringify({ title, message, linkUrl, variant });
  localStorage.setItem(ALERT_LOCALSTORAGE_KEY, payload);
};

/**
 * Return alert data from localStorage.
 */
export const retrieveAlert = () => {
  if (!AccessorUtilities.isLocalStorageAccessSafe()) {
    return null;
  }

  const initialAlertJSON = localStorage.getItem(ALERT_LOCALSTORAGE_KEY);
  // immediately clean up
  localStorage.removeItem(ALERT_LOCALSTORAGE_KEY);

  if (!initialAlertJSON) {
    return null;
  }

  return JSON.parse(initialAlertJSON);
};

export const getJwt = () => {
  return new Promise((resolve) => {
    if (isFunction(AP?.context?.getToken)) {
      AP.context.getToken((token) => {
        resolve(token);
      });
    } else {
      resolve();
    }
  });
};

export const getLocation = () => {
  return new Promise((resolve) => {
    if (isFunction(AP?.getLocation)) {
      AP.getLocation((location) => {
        resolve(location);
      });
    } else {
      resolve();
    }
  });
};

export const reloadPage = () => {
  if (isFunction(AP?.navigator?.reload)) {
    AP.navigator.reload();
  } else {
    window.location.reload();
  }
};

export const sizeToParent = () => {
  if (isFunction(AP?.sizeToParent)) {
    AP.sizeToParent();
  }
};
