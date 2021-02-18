export const AVAILABILITY_STATUS = {
  BUSY: 'busy',
  NOT_SET: 'not_set',
};

export const isUserBusy = (status = '') =>
  Boolean(status.length && status.toLowerCase().trim() === AVAILABILITY_STATUS.BUSY);
