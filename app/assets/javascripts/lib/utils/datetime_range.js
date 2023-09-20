import dateformat from '~/lib/dateformat';

export const isValidDateString = (dateString) => {
  if (typeof dateString !== 'string' || !dateString.trim()) {
    return false;
  }

  let isoFormatted;
  try {
    isoFormatted = dateformat(dateString, 'isoUtcDateTime');
  } catch (e) {
    if (e instanceof TypeError) {
      // not a valid date string
      return false;
    }
    throw e;
  }
  return !Number.isNaN(Date.parse(isoFormatted));
};
