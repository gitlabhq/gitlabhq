import { TITLE_LENGTH_MAX } from '~/issues/constants';
import { COLON, HYPHEN, NEWLINE } from '~/lib/utils/text_utility';
import { __ } from '~/locale';

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

const bulletTaskListItemRegex = /^\s*[-*]\s+\[.]\s+/;
const numericalTaskListItemRegex = /^\s*[0-9]\.\s+\[.]\s+/;
const codeMarkdownRegex = /^\s*`.*`\s*$/;
const imageOrLinkMarkdownRegex = /^\s*!?\[.*\)\s*$/;

/**
 * Checks whether the line of markdown contains a task list item,
 * i.e. `- [ ]`, `* [ ]`, or `1. [ ]`.
 *
 * @param {String} line A line of markdown
 * @returns {boolean} `true` if the line contains a task list item, otherwise `false`
 */
const containsTaskListItem = (line) =>
  bulletTaskListItemRegex.test(line) || numericalTaskListItemRegex.test(line);

/**
 * Deletes a task list item from the description.
 *
 * Starting from the task list item, it deletes each line until it hits a nested
 * task list item and reduces the indentation of each line from this line onwards.
 *
 * For example, for a given description like:
 *
 * <pre>
 * 1. [ ] item 1
 *
 *    paragraph text
 *
 *    1. [ ] item 2
 *
 *       paragraph text
 *
 *    1. [ ] item 3
 * </pre>
 *
 * Then when prompted to delete item 1, this function will return:
 *
 * <pre>
 * 1. [ ] item 2
 *
 *    paragraph text
 *
 * 1. [ ] item 3
 * </pre>
 *
 * @param {String} description Description in markdown format
 * @param {String} sourcepos Source position in format `23:3-23:14`
 * @returns {{newDescription: String, taskDescription: String, taskTitle: String}} Object with:
 *
 * - `newDescription` property that contains markdown with the deleted task list item omitted
 * - `taskDescription` property that contains the description of the deleted task list item
 * - `taskTitle` property that contains the title of the deleted task list item
 */
export const deleteTaskListItem = (description, sourcepos) => {
  const descriptionLines = description.split(NEWLINE);
  const [startIndex, endIndex] = getSourceposRows(sourcepos);

  const firstLine = descriptionLines[startIndex];
  const firstLineIndentation = firstLine.length - firstLine.trimStart().length;

  const taskTitle = firstLine
    .replace(bulletTaskListItemRegex, '')
    .replace(numericalTaskListItemRegex, '');
  const taskDescription = [];

  let indentation = 0;
  let linesToDelete = 1;
  let reduceIndentation = false;

  for (let i = startIndex + 1; i <= endIndex; i += 1) {
    if (reduceIndentation) {
      descriptionLines[i] = descriptionLines[i].slice(indentation);
    } else if (containsTaskListItem(descriptionLines[i])) {
      reduceIndentation = true;
      const currentLine = descriptionLines[i];
      const currentLineIndentation = currentLine.length - currentLine.trimStart().length;
      indentation = currentLineIndentation - firstLineIndentation;
      descriptionLines[i] = descriptionLines[i].slice(indentation);
    } else {
      taskDescription.push(descriptionLines[i].trimStart());
      linesToDelete += 1;
    }
  }

  descriptionLines.splice(startIndex, linesToDelete);

  return {
    newDescription: descriptionLines.join(NEWLINE),
    taskDescription: taskDescription.join(NEWLINE) || undefined,
    taskTitle,
  };
};

/**
 * Given a title and description for a task:
 *
 * - Moves characters beyond the 255 character limit from the title to the description
 * - Moves a pure markdown title to the description and gives the title the value `Untitled`
 *
 * @param {String} taskTitle The task title
 * @param {String} taskDescription The task description
 * @returns {{description: String, title: String}} An object with the formatted task title and description
 */
export const extractTaskTitleAndDescription = (taskTitle, taskDescription) => {
  const isTitleOnlyMarkdown =
    codeMarkdownRegex.test(taskTitle) || imageOrLinkMarkdownRegex.test(taskTitle);

  if (isTitleOnlyMarkdown) {
    return {
      title: __('Untitled'),
      description: taskDescription
        ? taskTitle.concat(NEWLINE, NEWLINE, taskDescription)
        : taskTitle,
    };
  }

  const isTitleTooLong = taskTitle.length > TITLE_LENGTH_MAX;

  if (isTitleTooLong) {
    return {
      title: taskTitle.slice(0, TITLE_LENGTH_MAX),
      description: taskDescription
        ? taskTitle.slice(TITLE_LENGTH_MAX).concat(NEWLINE, NEWLINE, taskDescription)
        : taskTitle.slice(TITLE_LENGTH_MAX),
    };
  }

  return {
    title: taskTitle,
    description: taskDescription,
  };
};

/**
 * Insert an element, such as a dropdown, next to a checkbox
 * in an issue/work item description rendered from markdown.
 *
 * @param element Element to insert
 * @param listItem The list item containing the checkbox
 */
export const insertNextToTaskListItemText = (element, listItem) => {
  const children = Array.from(listItem.children);
  const paragraph = children.find((el) => el.tagName === 'P');
  const list = children.find((el) => el.classList.contains('task-list'));

  if (paragraph) {
    // If there's a `p` element, then it's a multi-paragraph task item
    // and the task text exists within the `p` element as the last child
    paragraph.append(element);
  } else if (list) {
    // Otherwise, the task item can have a child list which exists directly after the task text
    list.insertAdjacentElement('beforebegin', element);
  } else {
    // Otherwise, the task item is a simple one where the task text exists as the last child
    listItem.append(element);
  }
};
