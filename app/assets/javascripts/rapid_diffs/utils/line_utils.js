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
  return pre.textContent.replace(/[\r\n]/g, '');
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

export function getNewLineRangeContent(diffElement, lineRange, side) {
  const { start, end } = lineRange;

  let row = findLineRow(diffElement, start.old_line, start.new_line);

  if (!row) return [];

  const endLine = end.new_line ?? end.old_line;
  const lines = [];

  while (row) {
    if (isRangeBoundary(row)) break;

    if ('hunkLines' in row.dataset) {
      const content = getNewLineContent(row, side);
      if (content === null) break;
      lines.push(content);

      const [oldLine, newLine] = getLineNumbers(row);
      if ((newLine ?? oldLine) >= endLine) break;
    }

    row = row.nextElementSibling;
  }

  return lines;
}
