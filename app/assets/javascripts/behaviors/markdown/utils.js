/**
 * This method parses raw markdown text in GFM input field and toggles checkboxes
 * based on checkboxChecked property.
 *
 * @param {Object} object containing rawMarkdown, sourcepos, checkboxChecked properties
 * @returns String with toggled checkboxes
 */
export const toggleMarkCheckboxes = ({ rawMarkdown, sourcepos, checkboxChecked }) => {
  // Extract the description text
  const [startRange] = sourcepos.split('-');
  let [startRow] = startRange.split(':');
  startRow = Number(startRow) - 1;

  // Mark/Unmark the checkboxes
  return rawMarkdown
    .split('\n')
    .map((row, index) => {
      if (startRow === index) {
        if (checkboxChecked) {
          return row.replace(/\[ \]/, '[x]');
        }
        return row.replace(/\[[x~]\]/i, '[ ]');
      }
      return row;
    })
    .join('\n');
};
