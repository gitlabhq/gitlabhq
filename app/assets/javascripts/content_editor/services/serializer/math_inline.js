const getNodeAfterMark = (mark, parent, index) => {
  let position = index;

  while (position < parent.childCount && mark.isInSet(parent.child(position).marks)) {
    position += 1;
  }

  return parent.maybeChild(position);
};

// A closing $ followed by a digit does not end inline math (so "$5 and $10" stays prose),
// so math followed by a digit is written in the $`x`$ form instead.
const startsWithDigit = (node) => /^\d/.test(node?.text ?? '');

const delimiters = (mark, parent, index) => {
  const { dollarMath, mathStyle } = mark.attrs;

  if (dollarMath && mathStyle === 'display') return { open: '$$', close: '$$' };
  if (!dollarMath || startsWithDigit(getNodeAfterMark(mark, parent, index))) {
    return { open: '$`', close: '`$' };
  }

  return { open: '$', close: '$' };
};

const mathInline = {
  open: (state, mark, ...position) => delimiters(mark, ...position).open,
  close: (state, mark, ...position) => delimiters(mark, ...position).close,
  mixable: true,
  escape: false,
  expelEnclosingWhitespace: true,
};

export default mathInline;
