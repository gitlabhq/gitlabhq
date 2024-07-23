/**
 * Highlight.js plugin for wrapping lines in the correct classes and attributes.
 * Needed to highlight a large amount of lines
 *
 * Plugin API: https://github.com/highlightjs/highlight.js/blob/main/docs/plugin-api.rst
 *
 * @param {String} content - represent highlighted line of code
 * @param {number} lineNum - represent highlighted line number
 * @param {Object} markLineInfo - highlighting info for the current line
 */
function markLinesWithDiv(content, lineNum, markLineInfo) {
  let wrappedLine = content;

  const stepNumberSpan =
    lineNum === markLineInfo?.startLine
      ? `<span class="inline-item-mark">${markLineInfo.index + 1}</span>`
      : '';
  const stepNumberSpanNone =
    lineNum !== markLineInfo?.startLine && markLineInfo
      ? `<span class="inline-item-mark gl-opacity-0">${markLineInfo.index + 1}</span>`
      : '';

  if (markLineInfo) {
    const contentStartIndex = content.indexOf(content.trimStart());
    wrappedLine = `${content.slice(
      0,
      contentStartIndex,
    )}${stepNumberSpanNone}<span id="TEXT-MARKER${
      markLineInfo.index + 1
    }-L${lineNum}" class="inline-section-marker">${stepNumberSpan}${content.slice(contentStartIndex)}</span>`;
  }
  return `<div class="line">${wrappedLine}</div>`;
}

export default (result, lineToMarkersInfo) => {
  // eslint-disable-next-line no-param-reassign
  result.value = result.value
    .split(/\r?\n/)
    .map((content, index) => markLinesWithDiv(content, index + 1, lineToMarkersInfo?.[index + 1]))
    .join('\n');
};
