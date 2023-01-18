import { AVAILABILITY_STATUS, NEVER_TIME_RANGE } from './constants';

export const isUserBusy = (status = '') =>
  Boolean(status.length && status.toLowerCase().trim() === AVAILABILITY_STATUS.BUSY);

export const computedClearStatusAfterValue = (value) => {
  if (value === null || value.name === NEVER_TIME_RANGE.name) {
    return null;
  }

  return value.shortcut;
};
