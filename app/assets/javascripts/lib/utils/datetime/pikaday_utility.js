export const pad = (val, len = 2) => `0${val}`.slice(-len);

/**
 * Formats dates in Pickaday
 * @param {String} dateString Date in yyyy-mm-dd format
 * @return {Date} UTC format
 */
export const parsePikadayDate = (dateString) => {
  const parts = dateString.split('-');
  const year = parseInt(parts[0], 10);
  const month = parseInt(parts[1] - 1, 10);
  const day = parseInt(parts[2], 10);

  return new Date(year, month, day);
};

/**
 * Used `onSelect` method in pickaday
 * @param {Date} date UTC format
 * @return {String} Date formatted in yyyy-mm-dd
 */
export const pikadayToString = (date) => {
  const day = pad(date.getDate());
  const month = pad(date.getMonth() + 1);
  const year = date.getFullYear();

  return `${year}-${month}-${day}`;
};
