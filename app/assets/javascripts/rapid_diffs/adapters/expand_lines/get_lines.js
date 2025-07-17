/**
 * @typedef {import('./diff_line_row').DiffLineRow} DiffLineRow
 */

import axios from '~/lib/utils/axios_utils';

const UNFOLD_COUNT = 20;

/**
 * @typedef {'up' | 'down' | 'both'} ExpandDirection
 * 'up' - ↑
 * 'down' - ↓
 * 'both' - ↕
 */
/**
 * @typedef {Object} RequestParams
 * @property {boolean} unfold - Adds hunk header (contains expand buttons) to the returned HTML
 * @property {number} since - Starting new line number for the line range
 * @property {number} to - Ending new line number for the line range
 * @property {boolean} bottom - Positions diff hunk header either before or after the lines
 * @property {number} offset - The difference between new and old line numbers
 * @property {number} [closest_line_number] - The next new line number near the existing diff hunk header
 * 'closest_line_number' - this param helps backend understand which expand buttons should be shown: ↑/↓ or ↕
 */
/**
 * @param {ExpandDirection} expandDirection
 * @param {[DiffLineRow, DiffLineRow]} surroundingLines
 * @returns {RequestParams}
 */
const getRequestParams = (expandDirection, [lineBefore, lineAfter]) => {
  switch (expandDirection) {
    case 'both':
      return {
        unfold: false,
        since: lineBefore.newLineNumber + 1,
        to: lineAfter.newLineNumber - 1,
        bottom: false,
        offset: lineBefore.newLineNumber - lineBefore.oldLineNumber,
      };
    case 'up':
      return {
        unfold: true,
        since: Math.max(lineAfter.newLineNumber - UNFOLD_COUNT, 1),
        to: lineAfter.newLineNumber - 1,
        closest_line_number: lineBefore ? lineBefore.newLineNumber : 0,
        offset: lineAfter.newLineNumber - lineAfter.oldLineNumber,
        bottom: false,
      };
    case 'down':
      return {
        unfold: true,
        since: lineBefore.newLineNumber + 1,
        to: lineBefore.newLineNumber + UNFOLD_COUNT,
        closest_line_number: lineAfter ? lineAfter.newLineNumber : 0,
        offset: lineBefore.newLineNumber - lineBefore.oldLineNumber,
        bottom: true,
      };
    default:
      // eslint-disable-next-line @gitlab/require-i18n-strings
      throw new Error('Invalid expand option provided');
  }
};

export const getLines = async ({ expandDirection, surroundingLines, diffLinesPath, view }) => {
  const params = getRequestParams(expandDirection, surroundingLines);
  const { data: lines } = await axios.get(diffLinesPath, { params: { ...params, view } });
  return lines;
};
