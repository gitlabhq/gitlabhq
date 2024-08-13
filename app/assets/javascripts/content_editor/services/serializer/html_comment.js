const htmlComment = (state, node) => {
  state.write('<!--');
  state.write(node.attrs.description || '');
  state.write('-->');
  state.closeBlock(node);
};

export default htmlComment;
