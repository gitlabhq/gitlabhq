export function getLineNumbers(row) {
  return [
    row.querySelector('[data-position="old"] [data-line-number]'),
    row.querySelector('[data-position="new"] [data-line-number]'),
  ].map((cell) => (cell ? Number(cell.dataset.lineNumber) : null));
}

export function getLineChange(cell) {
  return { change: cell.dataset.change, position: cell.dataset.position };
}

function getClosestLineNumber(row, position) {
  let current = row;
  while (current) {
    const el = current.querySelector(`[data-position="${position}"] [data-line-number]`);
    if (el) return Number(el.dataset.lineNumber);
    current = current.nextElementSibling;
  }
  return 0;
}

export function getLineCode({ id, row, oldLine, newLine }) {
  const left = oldLine ?? getClosestLineNumber(row, 'old');
  const right = newLine ?? getClosestLineNumber(row, 'new');
  return `${id}_${left}_${right}`;
}

export function getLinePosition(row, side) {
  const [oldLine, newLine] = getLineNumbers(row);
  return {
    old_line: !side || side === 'old' ? oldLine : null,
    new_line: !side || side === 'new' ? newLine : null,
  };
}

export function getChangeType(row, side) {
  const selector = side ? `[data-position="${side}"][data-change]` : '[data-change]';
  const cell = row.querySelector(selector);
  if (!cell) return null;
  return cell.dataset.change === 'added' ? 'new' : 'old';
}

export function getRowPosition(row, side) {
  const type = getChangeType(row, side);
  return { ...getLinePosition(row, type ? side : undefined), type };
}

function getNewLineContent(row, side) {
  // In parallel view, content cells have data-position so the positioned
  // query finds the correct side. In inline view they don't, so we fall
  // back to the first <pre> in the row.
  let pre = null;
  if (side) pre = row.querySelector(`[data-position="${side}"] pre`);
  if (!pre) pre = row.querySelector('pre');

  if (!pre || pre.closest('[data-change="removed"]')) return null;

  // Each <pre> is one diff line. Strip all CR and LF: the trailing LF is
  // the highlighter's line terminator, and any internal ones are control
  // characters the browser converted — they break text_markdown.js which
  // splits on \n to detect multi-line selections.
  return pre.textContent.replace(/[\r\n]/g, '').replace(/\\n/g, '\uE000');
}

export function isRangeBoundary(row) {
  return row.dataset.hunkHeader != null || Boolean(row.querySelector('[data-change="meta"]'));
}

export function findLineRow(element, oldLine, newLine) {
  return element
    .querySelector(
      `[data-position="${oldLine ? 'old' : 'new'}"] [data-line-number="${oldLine || newLine}"]`,
    )
    ?.closest('tr');
}

// Returns null unless every new-file line in the range is rendered, so a suggestion is
// never prefilled with part of the code it replaces.
export function getNewLinesInRange(diffElement, lineRange) {
  const { start, end } = lineRange;
  const endLine = end.new_line;
  if (!endLine) return null;

  const startRow = findLineRow(diffElement, start.old_line, start.new_line);
  if (!startRow) return null;

  const { rows } = startRow.closest('table');
  const lines = [];
  let firstLine = null;
  let lastLine = null;

  for (let i = startRow.rowIndex; i < rows.length && lastLine !== endLine; i += 1) {
    const row = rows[i];
    if (isRangeBoundary(row)) return null;

    const [, newLine] = 'hunkLines' in row.dataset ? getLineNumbers(row) : [];
    if (newLine) {
      if (lastLine !== null && newLine !== lastLine + 1) return null;
      const content = getNewLineContent(row, 'new');
      if (content === null) return null;
      lines.push(content);
      firstLine ??= newLine;
      lastLine = newLine;
    }
  }

  if (lastLine !== endLine) return null;
  return { lines, start: firstLine, end: endLine };
}
