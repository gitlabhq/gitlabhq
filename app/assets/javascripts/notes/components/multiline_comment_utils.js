import { takeRightWhile } from 'lodash';

export function getSymbol(type) {
  if (type === 'new') return '+';
  if (type === 'old') return '-';
  return '';
}

function getLineNumber(lineRange, key) {
  if (!lineRange || !key || !lineRange[key]) return '';
  const { new_line: newLine, old_line: oldLine, type } = lineRange[key];
  const otherKey = key === 'start' ? 'end' : 'start';

  // By default we want to see the "old" or "left side" line number
  // The exception is if the "end" line is on the "right" side
  // `otherLineType` is only used if `type` is null to make sure the line
  // number relfects the "right" side number, if that is the side
  // the comment form is located on
  const otherLineType = !type ? lineRange[otherKey]?.type : null;
  const lineType = type || '';
  let lineNumber = oldLine;
  if (lineType === 'new' || otherLineType === 'new') lineNumber = newLine;
  return (lineNumber && getSymbol(lineType) + lineNumber) || '';
}

export function getStartLineNumber(lineRange) {
  return getLineNumber(lineRange, 'start');
}

export function getEndLineNumber(lineRange) {
  return getLineNumber(lineRange, 'end');
}

export function getLineClasses(line) {
  const symbol = typeof line === 'string' ? line.charAt(0) : getSymbol(line?.type);

  if (symbol !== '+' && symbol !== '-') return '';

  return [
    'gl-px-1 gl-rounded-small gl-border-solid gl-border-1 gl-border-white',
    {
      'gl-bg-status-success gl-text-status-success': symbol === '+',
      'gl-bg-status-danger gl-text-status-danger': symbol === '-',
    },
  ];
}

// eslint-disable-next-line max-params
export function commentLineOptions(diffLines, startingLine, lineCode, side = 'left') {
  const preferredSide = side === 'left' ? 'old_line' : 'new_line';
  const fallbackSide = preferredSide === 'new_line' ? 'old_line' : 'new_line';
  const notMatchType = (l) => l.type !== 'match';
  const linesCopy = [...diffLines]; // don't mutate the argument
  const startingLineCode = startingLine.line_code;

  const currentIndex = linesCopy.findIndex((line) => line.line_code === lineCode);

  // We're limiting adding comments to only lines above the current line
  // to make rendering simpler. Future interations will use a more
  // intuitive dragging interface that will make this unnecessary
  const upToSelected = linesCopy.slice(0, currentIndex + 1);

  // Only include the lines up to the first "Show unchanged lines" block
  // i.e. not a "match" type
  const lines = takeRightWhile(upToSelected, notMatchType);

  // If the selected line is "hidden" in an unchanged line block
  // or "above" the current group of lines add it to the array so
  // that the drop down is not defaulted to empty
  const selectedIndex = lines.findIndex((line) => line.line_code === startingLineCode);
  if (selectedIndex < 0) lines.unshift(startingLine);

  return lines.map((l) => {
    const { line_code, type, old_line, new_line } = l;
    return {
      value: { line_code, type, old_line, new_line },
      text: `${getSymbol(type)}${l[preferredSide] || l[fallbackSide]}`,
    };
  });
}

export function formatLineRange(start, end) {
  const extractProps = ({ line_code, type, old_line, new_line }) => ({
    line_code,
    type,
    old_line,
    new_line,
  });
  return {
    start: extractProps(start),
    end: extractProps(end),
  };
}

export function getCommentedLines(selectedCommentPosition, diffLines) {
  if (!selectedCommentPosition) {
    // This structure simplifies the logic that consumes this result
    // by keeping the returned shape the same and adjusting the bounds
    // to something unreachable. This way our component logic stays:
    // "if index between start and end"
    return {
      startLine: diffLines.length + 1,
      endLine: diffLines.length + 1,
    };
  }

  const findLineCodeIndex = (line) => (position) => {
    return [position.line_code, position.left?.line_code, position.right?.line_code].includes(
      line.line_code,
    );
  };

  const { start, end } = selectedCommentPosition;
  const startLine = diffLines.findIndex(findLineCodeIndex(start));
  const endLine = diffLines.findIndex(findLineCodeIndex(end));

  return { startLine, endLine };
}
