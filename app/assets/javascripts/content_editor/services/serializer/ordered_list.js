function orderedList(state, node) {
  const start = node.attrs.start || 1;
  const delimiter = node.attrs.parens ? ')' : '.';

  const maxW = String(start + node.childCount - 1).length;
  const space = state.repeat(' ', maxW + 2);

  state.renderList(node, space, (i) => {
    const nStr = String(start + i);
    return `${state.repeat(' ', maxW - nStr.length) + nStr}${delimiter} `;
  });
}

export default orderedList;
