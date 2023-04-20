import { sanitize } from '~/lib/dompurify';

/**
 * Converts a dataframe in the output of a Jupyter Notebook cell to a json object
 *
 * @param {string} input - the dataframe
 * @param {DOMParser} parser - the html parser
 * @returns {Object} The converted JSON object with an `items` property containing the rows.
 */
export function convertHtmlTableToJson(input, domParser) {
  const parser = domParser || new DOMParser();
  const htmlDoc = parser.parseFromString(sanitize(input), 'text/html');

  if (!htmlDoc) return { fields: [], items: [] };

  const columnNames = [...htmlDoc.querySelectorAll('table > thead th')].map(
    (head) => head.innerText,
  );

  if (!columnNames) return { fields: [], items: [] };

  const itemValues = [...htmlDoc.querySelectorAll('table > tbody > tr')].map((row) =>
    [...row.querySelectorAll('td')].map((item) => item.innerText),
  );

  return {
    fields: columnNames.map((column) => ({
      key: column === '' ? 'index' : column,
      label: column,
      sortable: true,
    })),
    items: itemValues.map((values, itemIndex) => ({
      index: itemIndex,
      ...Object.fromEntries(values.map((value, index) => [columnNames[index + 1], value])),
    })),
  };
}

export function isDataframe(output) {
  const htmlData = output.data['text/html'];
  if (!htmlData) return false;

  return htmlData.slice(0, 20).some((line) => line.includes('dataframe'));
}
