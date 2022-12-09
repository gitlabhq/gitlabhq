import { AVAILABILITY_STATUS } from './constants';

export const isUserBusy = (status = '') =>
  Boolean(status.length && status.toLowerCase().trim() === AVAILABILITY_STATUS.BUSY);
