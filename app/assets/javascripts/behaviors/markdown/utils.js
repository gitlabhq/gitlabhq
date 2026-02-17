/**
 * Parse a CommonMark-style sourcepos line-column pair, like '1:5' (first line, 5th column),
 * into a JavaScript object with zero-based indices, like `{ line: 0, column: 4 }`.
 */
const parseLineColumn = (lineColumn) => {
  const [line, column] = lineColumn.split(':');
  return { line: Number(line) - 1, column: Number(column) - 1 };
};

/**
 * Parse a CommonMark-style sourcepos, like '1:5-1:8' (columns 5 through 8 inclusive of the first line)
 * into a JavaScript object with zero-based indices, like
 * `{ start: { line: 0, column: 4 }, end: { line: 0, column: 7 } }`.
 */
const parseSourcepos = (sourcepos) => {
  const [start, end] = sourcepos.split('-');
  return { start: parseLineColumn(start), end: parseLineColumn(end) };
};

const toggleCheckboxPrecise = (line, sourcepos, checkboxChecked) => {
  if (
    !(sourcepos.start.line === sourcepos.end.line && sourcepos.end.column >= sourcepos.start.column)
  )
    return null;

  // Possibly precise sourcepos given; check that a task item does appear to be exactly there and set accordingly.
  // Return `line` (whether changed or unchanged) if we did match a checkbox at the target; otherwise
  // return null and do an imprecise replacement.

  // Avoid underflow if given an unrealistic start column (task item symbol can't be at position 0,
  // since the '[' character must come before it).
  if (sourcepos.start.column <= 0) return null;

  const lineBefore = line.substr(0, sourcepos.start.column - 1);
  const lineItem = line.substr(sourcepos.start.column - 1, 3);
  const lineAfter = line.substr(sourcepos.start.column + 2);

  if (checkboxChecked && lineItem.match(/\[\p{Space_Separator}\]/u)) {
    return `${lineBefore}[x]${lineAfter}`;
  }
  if (!checkboxChecked && lineItem.match(/\[x\]/i)) {
    return `${lineBefore}[ ]${lineAfter}`;
  }

  return null;
};

/**
 * This method does its best to toggle a task item in GLFM based on the given source position,
 * settings its state to checkboxChecked.  A parallel service on the backend is TaskListToggleService.
 *
 * The source position can be given directly in the 'sourcepos' property, or the checkbox <input> DOM
 * node can be given in the 'target' property, in which case the best sourcepos is obtained directly.
 *
 * If the sourcepos range precisely identifies a valid task list symbol in the source, it is replaced
 * exactly. This was added in our Markdown parser recently: https://github.com/kivikakk/comrak/pull/705.
 *
 * If not (such as for all cached Markdown renders), we assume it's the list item's sourcepos, and replace
 * the first task item-looking sequence we find in the line.
 *
 * The old content of the line (pre-replacement) is returned in oldLine, the full new Markdown document
 * in newMarkdown, and the sourcepos that was used to do the replacement (whether given directly or
 * obtained from a DOM node) is returned in sourcepos.
 *
 * @param {Object} object containing rawMarkdown, checkboxChecked properties, and one of sourcepos or target
 * @returns {Object} object containing oldLine, newMarkdown, sourcepos properties
 */
export const toggleCheckbox = ({ rawMarkdown, checkboxChecked, ...args }) => {
  let rawSourcepos;

  if (args.sourcepos) {
    rawSourcepos = args.sourcepos;
  } else if (args.target) {
    rawSourcepos =
      args.target.dataset.checkboxSourcepos ?? args.target.parentElement.dataset.sourcepos;
  }

  if (!rawSourcepos) return null;

  const sourcepos = parseSourcepos(rawSourcepos);
  const lines = rawMarkdown.split('\n');
  const line = lines[sourcepos.start.line];

  // Attempt precise sourcepos replacement, falling back to imprecise on failure
  // (replace first task item-looking thing on the line).

  const linePrecise = toggleCheckboxPrecise(line, sourcepos, checkboxChecked);
  if (linePrecise !== null) {
    lines[sourcepos.start.line] = linePrecise;
  } else {
    lines[sourcepos.start.line] = line.replace(
      /\[(?:\p{Space_Separator}|x|~)\]/iu,
      checkboxChecked ? '[x]' : '[ ]',
    );
  }

  return {
    oldLine: line,
    newMarkdown: lines.join('\n'),
    sourcepos: rawSourcepos,
  };
};
