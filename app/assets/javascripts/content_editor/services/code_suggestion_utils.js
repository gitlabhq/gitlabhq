export function langParamsToLineOffset(langParams) {
  if (!langParams) return [0, 0];
  const match = langParams.match(/([-+]\d+)([-+]\d+)/);
  return match ? [parseInt(match[1], 10), parseInt(match[2], 10)] : [0, 0];
}

export function lineOffsetToLangParams(lineOffset) {
  let langParams = '';
  langParams += lineOffset[0] <= 0 ? `-${-lineOffset[0]}` : `+${lineOffset[0]}`;
  langParams += lineOffset[1] < 0 ? lineOffset[1] : `+${lineOffset[1]}`;
  return langParams;
}

export function toAbsoluteLineOffset(lineOffset, lineNumber) {
  return [lineOffset[0] + lineNumber, lineOffset[1] + lineNumber];
}

export function getLines(absoluteLineOffset, allLines) {
  return allLines.slice(absoluteLineOffset[0] - 1, absoluteLineOffset[1]);
}

// \u200b is a zero width space character (Alternatively &ZeroWidthSpace;, &#8203; or &#x200B;).
// Due to the nature of HTML, if you have a blank line in the deleted/inserted code, it would
// render with 0 height. (Each line is in its <code> element.) This means that blank lines
// would be skipped when rendering the diff.
// We append this character to the end of each line to make sure that the line is not empty
// and the line numbers are rendered correctly.
const ZERO_WIDTH_SPACE = '\u200b';

export function appendNewlines(lines) {
  return lines.map((l, i, arr) => `${l}${ZERO_WIDTH_SPACE}${i === arr.length - 1 ? '' : '\n'}`);
}
