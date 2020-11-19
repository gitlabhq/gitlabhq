export const AVAILABILITY_STATUS = {
  BUSY: 'busy',
  NOT_SET: 'not_set',
};

export const isUserBusy = status => status === AVAILABILITY_STATUS.BUSY;

export const isValidAvailibility = availability =>
  availability.length ? Object.values(AVAILABILITY_STATUS).includes(availability) : true;
