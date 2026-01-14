function horizontalRule(state, node) {
  state.write(node.attrs.markup || '---');
  state.closeBlock(node);
}

export default horizontalRule;
