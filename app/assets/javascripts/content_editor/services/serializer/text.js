const text = (state, node) => {
  state.text(node.text, !state.inAutolink);
};

export default text;
