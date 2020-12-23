export const parseUserIds = (userIds) => userIds.split(/\s*,\s*/g);

export const stringifyUserIds = (userIds) => userIds.join(',');

export const getErrorMessages = (error) =>
  [].concat(error?.response?.data?.message ?? error.message);
