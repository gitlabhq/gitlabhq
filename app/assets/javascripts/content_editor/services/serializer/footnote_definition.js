function footnoteDefinition(state, node) {
  state.write(`[^${node.attrs.identifier}]: `);
  state.renderInline(node);
  state.ensureNewLine();
}

export default footnoteDefinition;
