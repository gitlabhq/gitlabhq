const emoji = (state, node) => {
  const { name } = node.attrs;

  state.write(`:${name}:`);
};

export default emoji;
