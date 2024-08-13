import { getLines } from '~/rapid_diffs/expand_lines/get_lines';

const getLineNumber = (el) => parseInt(el.dataset.linenumber, 10);

const collectLineData = (element) => {
  const buttons = element.querySelectorAll('[data-linenumber]');
  const lineNumbers = Array.from(buttons).map(getLineNumber);
  const previousEl = element.previousElementSibling;
  const prevNewLine = previousEl?.querySelector('[data-linenumber]:last-child');
  const prevNewLineNumber = prevNewLine ? getLineNumber(prevNewLine) : 0;
  return [...lineNumbers, prevNewLineNumber];
};

const viewersMap = {
  text_inline: 'text',
  text_parallel: 'parallel',
};

/** @type {diffFileAdapter} */
export const ExpandLinesAdapter = {
  async onClick(event) {
    const { target } = event;
    const { expandPrevLine, expandNextLine } = target.dataset;
    const parent = target.closest('tr');
    if (parent.dataset.loading || (!expandPrevLine && !expandNextLine)) return;

    parent.dataset.loading = true;

    const { blobDiffPath } = this.diffElement.dataset;
    const lines = await getLines({
      expandPrevLine,
      lineData: collectLineData(parent),
      blobDiffPath,
      view: viewersMap[this.viewer],
    });

    const method = expandPrevLine ? 'beforebegin' : 'afterend';
    // eslint-disable-next-line no-unsanitized/method
    parent.insertAdjacentHTML(method, lines);
    parent.remove();
  },
};
