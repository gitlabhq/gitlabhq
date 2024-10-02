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
