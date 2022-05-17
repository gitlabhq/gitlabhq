import { COLON, HYPHEN, NEWLINE } from '~/lib/utils/text_utility';

/**
 * Get the index from sourcepos that represents the line of
 * the description when the description is split by newline.
 *
 * @param {String} sourcepos Source position in format `23:3-23:14`
 * @returns {Number} Index of description split by newline
 */
const getDescriptionIndex = (sourcepos) => {
  const [startRange] = sourcepos.split(HYPHEN);
  const [startRow] = startRange.split(COLON);
  return startRow - 1;
};

/**
 * Given a `ul` or `ol` element containing a new sort order, this function performs
 * a depth-first search to get the new sort order in the form of sourcepos indices.
 *
 * @param {HTMLElement} list A `ul` or `ol` element containing a new sort order
 * @returns {Array<Number>} An array representing the new order of the list
 */
const getNewSourcePositions = (list) => {
  const newSourcePositions = [];

  function pushPositionOfChildListItems(el) {
    if (!el) {
      return;
    }
    if (el.tagName === 'LI') {
      newSourcePositions.push(getDescriptionIndex(el.dataset.sourcepos));
    }
    Array.from(el.children).forEach(pushPositionOfChildListItems);
  }

  pushPositionOfChildListItems(list);

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
 * <ul data-sourcepos="3:1-8:0">
 *   <li data-sourcepos="4:1-4:8">
 *     Item 2
 *     <ul data-sourcepos="5:1-6:10">
 *       <li data-sourcepos="5:1-5:10">Item 3</li>
 *       <li data-sourcepos="6:1-6:10">Item 4</li>
 *     </ul>
 *   </li>
 *   <li data-sourcepos="3:1-3:8">Item 1</li>
 *   <li data-sourcepos="7:1-8:0">Item 5</li>
 * <ul>
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
  const startIndexOfList = getDescriptionIndex(list.dataset.sourcepos);

  getNewSourcePositions(list)
    .map((lineIndex) => descriptionLines[lineIndex])
    .forEach((line, index) => {
      descriptionLines[startIndexOfList + index] = line;
    });

  return descriptionLines.join(NEWLINE);
};
