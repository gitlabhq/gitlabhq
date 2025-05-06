import { getLines } from '~/rapid_diffs/expand_lines/get_lines';
import { DiffLineRow } from '~/rapid_diffs/expand_lines/diff_line_row';
import { createAlert } from '~/alert';
import { s__ } from '~/locale';

const getSurroundingLines = (hunkHeaderRow) => {
  const wrapperElements = Array.from(hunkHeaderRow.parentElement.children);
  const rowIndex = wrapperElements.indexOf(hunkHeaderRow);
  const lineBefore = wrapperElements.slice(0, rowIndex).findLast((el) => 'hunkLines' in el.dataset);
  const lineAfter = wrapperElements
    .slice(rowIndex, wrapperElements.length)
    .find((el) => 'hunkLines' in el.dataset);
  return [lineBefore, lineAfter].map((lineRow) => (lineRow ? new DiffLineRow(lineRow) : null));
};

export const ExpandLinesAdapter = {
  clicks: {
    async expandLines(event, button) {
      const { expandDirection } = button.dataset;
      const hunkHeaderRow = button.closest('tr');

      if (hunkHeaderRow.dataset.loading) return;
      hunkHeaderRow.dataset.loading = expandDirection;
      button.setAttribute('disabled', 'disabled');

      const { diffLinesPath } = this.data;
      let lines;
      try {
        lines = await getLines({
          expandDirection,
          surroundingLines: getSurroundingLines(hunkHeaderRow),
          diffLinesPath,
          view: this.viewer === 'text_parallel' ? 'parallel' : undefined,
        });
      } catch (error) {
        createAlert({
          message: s__('RapidDiffs|Failed to expand lines, please try again.'),
          error,
        });
        delete hunkHeaderRow.dataset.loading;
        button.removeAttribute('disabled');
        return;
      }

      if (expandDirection === 'up') {
        // eslint-disable-next-line no-unsanitized/method
        hunkHeaderRow.insertAdjacentHTML('beforebegin', lines);
        hunkHeaderRow.previousElementSibling.querySelector('[data-line-number]').focus();
      } else {
        // eslint-disable-next-line no-unsanitized/method
        hunkHeaderRow.insertAdjacentHTML('afterend', lines);
        hunkHeaderRow.nextElementSibling.querySelector('[data-line-number]').focus();
      }
      hunkHeaderRow.remove();
    },
  },
};
