import AccessorUtilities from '~/lib/utils/accessor';
import { ALERT_LOCALSTORAGE_KEY, BASE_URL_LOCALSTORAGE_KEY } from './constants';

const isFunction = (fn) => typeof fn === 'function';
const { canUseLocalStorage } = AccessorUtilities;

const persistToStorage = (key, payload) => {
  localStorage.setItem(key, payload);
};

const retrieveFromStorage = (key) => {
  return localStorage.getItem(key);
};

const removeFromStorage = (key) => {
  localStorage.removeItem(key);
};

/**
 * Persist alert data to localStorage.
 */
export const persistAlert = ({ title, message, linkUrl, variant } = {}) => {
  if (!canUseLocalStorage()) {
    return;
  }

  const payload = JSON.stringify({ title, message, linkUrl, variant });
  persistToStorage(ALERT_LOCALSTORAGE_KEY, payload);
};

/**
 * Return alert data from localStorage.
 */
export const retrieveAlert = () => {
  if (!canUseLocalStorage()) {
    return null;
  }

  const initialAlertJSON = retrieveFromStorage(ALERT_LOCALSTORAGE_KEY);
  // immediately clean up
  removeFromStorage(ALERT_LOCALSTORAGE_KEY);

  if (!initialAlertJSON) {
    return null;
  }

  return JSON.parse(initialAlertJSON);
};

export const persistBaseUrl = (baseUrl) => {
  if (!canUseLocalStorage()) {
    return;
  }

  persistToStorage(BASE_URL_LOCALSTORAGE_KEY, baseUrl);
};

export const retrieveBaseUrl = () => {
  if (!canUseLocalStorage()) {
    return null;
  }

  return retrieveFromStorage(BASE_URL_LOCALSTORAGE_KEY);
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
