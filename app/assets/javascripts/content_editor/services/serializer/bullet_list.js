function bulletList(state, node) {
  const { bullet: bulletAttr } = node.attrs;
  const bullet = bulletAttr || '*';

  state.renderList(node, '  ', () => `${bullet} `);
}

export default bulletList;
