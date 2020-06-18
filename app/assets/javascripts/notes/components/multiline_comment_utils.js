import { takeRightWhile } from 'lodash';

export function getSymbol(type) {
  if (type === 'new') return '+';
  if (type === 'old') return '-';
  return '';
}

function getLineNumber(lineRange, key) {
  if (!lineRange || !key) return '';
  const lineCode = lineRange[`${key}_line_code`] || '';
  const lineType = lineRange[`${key}_line_type`] || '';
  const lines = lineCode.split('_') || [];
  const lineNumber = lineType === 'old' ? lines[1] : lines[2];
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
      'gl-bg-green-100 gl-text-green-800': symbol === '+',
      'gl-bg-red-100 gl-text-red-800': symbol === '-',
    },
  ];
}

export function commentLineOptions(diffLines, lineCode) {
  const selectedIndex = diffLines.findIndex(line => line.line_code === lineCode);
  const notMatchType = l => l.type !== 'match';

  // We're limiting adding comments to only lines above the current line
  // to make rendering simpler. Future interations will use a more
  // intuitive dragging interface that will make this unnecessary
  const upToSelected = diffLines.slice(0, selectedIndex + 1);

  // Only include the lines up to the first "Show unchanged lines" block
  // i.e. not a "match" type
  const lines = takeRightWhile(upToSelected, notMatchType);

  return lines.map(l => ({
    value: { lineCode: l.line_code, type: l.type },
    text: `${getSymbol(l.type)}${l.new_line || l.old_line}`,
  }));
}
