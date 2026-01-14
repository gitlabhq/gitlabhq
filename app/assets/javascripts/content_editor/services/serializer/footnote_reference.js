function footnoteReference(state, node) {
  state.write(`[^${node.attrs.identifier}]`);
}

export default footnoteReference;
