/* eslint-disable no-console */
export const LOG_PREFIX = '[gitlab]';

export const logError = (message = '', ...args) => {
  console.error(LOG_PREFIX, `${message}\n`, ...args);
};
