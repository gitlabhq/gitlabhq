/**
 * Replaces line break with an empty space
 * @param {*} data
 */
export const removeBreakLine = (data) => data.replace(/\r?\n|\r/g, ' ');

/**
 * Removes line breaks, spaces and trims the given text
 * @param {String} str
 * @returns {String}
 */
export const trimText = (str) =>
  str
    .replace(/\r?\n|\r/g, '')
    .replace(/\s\s+/g, ' ')
    .trim();

export const removeWhitespace = (str) => str.replace(/\s\s+/g, ' ');
