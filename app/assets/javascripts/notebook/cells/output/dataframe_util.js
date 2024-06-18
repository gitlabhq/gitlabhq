import { sanitize } from '~/lib/dompurify';

function parseItems(itemIndexes, itemColumns) {
  // Fetching items: if the dataframe has a single column index, the table is simple
  // 0: tr > th(index0 value) th(column0 value) th(column1 value)
  // 1: tr > th(index0 value) th(column0 value) th(column1 value)
  //
  // But if the dataframe has multiple column indexes, it uses rowspan, and the row below won't have a value for that
  // index.
  // 0: tr > th(index0 value, rowspan=2) th(index1 value) th(column0 value) th(column1 value)
  // 1: tr >                             th(index1 value) th(column0 value) th(column1 value)
  //
  // So, when parsing row 1, and the count of <th> elements is less than indexCount, we fill with the first
  // values of row 0
  const indexCount = itemIndexes[0].length;
  const rowCount = itemIndexes.length;

  const filledIndexes = itemIndexes.map((row, rowIndex) => {
    const indexesInRow = row.length;
    if (indexesInRow === indexCount) {
      return row;
    }
    return itemIndexes[rowIndex - 1].slice(0, -indexesInRow).concat(row);
  });

  const items = Array(rowCount);

  for (let row = 0; row < rowCount; row += 1) {
    items[row] = {
      ...Object.fromEntries(filledIndexes[row].map((value, counter) => [`index${counter}`, value])),
      ...Object.fromEntries(itemColumns[row].map((value, counter) => [`column${counter}`, value])),
    };
  }
  return items;
}

function labelsToFields(labels, isIndex = true) {
  return labels.map((label, counter) => ({
    key: isIndex ? `index${counter}` : `column${counter}`,
    label,
    sortable: true,
    class: isIndex ? 'gl-font-bold' : '',
  }));
}

function parseFields(columnAndIndexLabels, indexCount, columnCount) {
  // Fetching the labels: if the dataframe has a single column index, it will be in the format:
  // thead
  //   tr
  //     th(index0 label) th(column0 label) th(column1 label)
  //
  // If there are multiple index columns, it the header will actually have two rows:
  // thead
  //   tr
  //     th() th() th(column 0 label) th(column1 label)
  //   tr
  //     th(index0 label) th(index1 label) th() th()

  const columnLabels = columnAndIndexLabels[0].slice(-columnCount);
  const indexLabels = columnAndIndexLabels[columnAndIndexLabels.length - 1].slice(0, indexCount);

  const indexFields = labelsToFields(indexLabels, true);
  const columnFields = labelsToFields(columnLabels, false);

  return [...indexFields, ...columnFields];
}

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

  const columnAndIndexLabels = [...htmlDoc.querySelectorAll('table > thead tr')].map((row) =>
    [...row.querySelectorAll('th')].map((item) => item.innerText),
  );

  if (columnAndIndexLabels.length === 0) return { fields: [], items: [] };

  const tableRows = [...htmlDoc.querySelectorAll('table > tbody > tr')];

  const itemColumns = tableRows.map((row) =>
    [...row.querySelectorAll('td')].map((item) => item.innerText),
  );

  const itemIndexes = tableRows.map((row) =>
    [...row.querySelectorAll('th')].map((item) => item.innerText),
  );

  const fields = parseFields(columnAndIndexLabels, itemIndexes[0].length, itemColumns[0].length);
  const items = parseItems(itemIndexes, itemColumns);

  return { fields, items };
}

export function isDataframe(output) {
  const htmlData = output.data['text/html'];
  if (!htmlData) return false;

  return htmlData.slice(0, 20).some((line) => line.includes('dataframe'));
}
