import { COLON, HYPHEN, NEWLINE } from '~/lib/utils/text_utility';

/**
 * Returns the start and end `sourcepos` rows, converted to zero-based numbering.
 *
 * @param {String} sourcepos Source position in format `23:3-23:14`
 * @returns {Array<Number>} Start and end `sourcepos` rows, zero-based numbered
 */
const getSourceposRows = (sourcepos) => {
  const [startRange, endRange] = sourcepos.split(HYPHEN);
  const [startRow] = startRange.split(COLON);
  const [endRow] = endRange.split(COLON);
  return [startRow - 1, endRow - 1];
};

/**
 * Given a `ul` or `ol` element containing a new sort order, this function returns
 * an array of this new order which is derived from its list items' sourcepos values.
 *
 * @param {HTMLElement} list A `ul` or `ol` element containing a new sort order
 * @returns {Array<Number>} A numerical array representing the new order of the list.
 * The numbers represent the rows of the original markdown source.
 */
const getNewSourcePositions = (list) => {
  const newSourcePositions = [];

  Array.from(list.children).forEach((listItem) => {
    const [start, end] = getSourceposRows(listItem.dataset.sourcepos);
    for (let i = start; i <= end; i += 1) {
      newSourcePositions.push(i);
    }
  });

  return newSourcePositions;
};

/**
 * Converts a description to one with a new list sort order.
 *
 * Given a description like:
 *
 * <pre>
 * 1. I am text
 * 2.
 * 3. - Item 1
 * 4. - Item 2
 * 5.   - Item 3
 * 6.   - Item 4
 * 7. - Item 5
 * </pre>
 *
 * And a reordered list (due to dragging Item 2 into Item 1's position) like:
 *
 * <pre>
 * <ul data-sourcepos="3:1-7:8">
 *   <li data-sourcepos="4:1-6:10">
 *     Item 2
 *     <ul data-sourcepos="5:3-6:10">
 *       <li data-sourcepos="5:3-5:10">Item 3</li>
 *       <li data-sourcepos="6:3-6:10">Item 4</li>
 *     </ul>
 *   </li>
 *   <li data-sourcepos="3:1-3:8">Item 1</li>
 *   <li data-sourcepos="7:1-7:8">Item 5</li>
 * </ul>
 * </pre>
 *
 * This function returns:
 *
 * <pre>
 * 1. I am text
 * 2.
 * 3. - Item 2
 * 4.   - Item 3
 * 5.   - Item 4
 * 6. - Item 1
 * 7. - Item 5
 * </pre>
 *
 * @param {String} description Description in markdown format
 * @param {HTMLElement} list A `ul` or `ol` element containing a new sort order
 * @returns {String} Markdown with a new list sort order
 */
export const convertDescriptionWithNewSort = (description, list) => {
  const descriptionLines = description.split(NEWLINE);
  const [startIndexOfList] = getSourceposRows(list.dataset.sourcepos);

  getNewSourcePositions(list)
    .map((lineIndex) => descriptionLines[lineIndex])
    .forEach((line, index) => {
      descriptionLines[startIndexOfList + index] = line;
    });

  return descriptionLines.join(NEWLINE);
};
