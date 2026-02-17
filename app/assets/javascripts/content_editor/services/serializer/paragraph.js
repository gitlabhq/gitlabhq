function paragraph(state, node) {
  state.renderInline(node);
  state.closeBlock(node);
}

export default paragraph;
