import { HIGHLIGHT_LINES, CLEAR_HIGHLIGHT } from '~/rapid_diffs/adapter_events';

function lineSelector(pos) {
  const side = pos.old_line ? 'old' : 'new';
  const line = pos.old_line || pos.new_line;
  return `[data-position="${side}"] [data-line-number="${line}"]`;
}

function findLineRows(diffElement, { start, end }) {
  const startRow = diffElement.querySelector(lineSelector(start))?.closest('[data-hunk-lines]');
  const endRow = diffElement.querySelector(lineSelector(end))?.closest('[data-hunk-lines]');
  if (!startRow || !endRow) return [];
  const rows = [...diffElement.querySelectorAll('[data-hunk-lines]')];
  const startIndex = rows.indexOf(startRow);
  const endIndex = rows.indexOf(endRow);
  const from = Math.min(startIndex, endIndex);
  const to = Math.max(startIndex, endIndex);
  return rows.slice(from, to + 1);
}

function clearHighlightedRows(diffElement) {
  diffElement.querySelectorAll('[data-highlight]').forEach((el) => {
    delete el.dataset.highlight;
  });
}

/* eslint-disable no-param-reassign */
function highlightRows(diffElement, rows) {
  clearHighlightedRows(diffElement);
  rows.forEach((row) => {
    row.dataset.highlight = '';
  });
  if (rows[0]) rows[0].dataset.highlight = 'start';
  if (rows[rows.length - 1]) rows[rows.length - 1].dataset.highlight += ' end'; // eslint-disable-line @gitlab/require-i18n-strings
}
/* eslint-enable no-param-reassign */

export const lineHighlightingAdapter = {
  [HIGHLIGHT_LINES](lineRange) {
    highlightRows(this.diffElement, findLineRows(this.diffElement, lineRange));
  },
  [CLEAR_HIGHLIGHT]() {
    clearHighlightedRows(this.diffElement);
  },
};
