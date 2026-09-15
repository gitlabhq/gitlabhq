const blobEmbed = (state, node) => {
  if (node.attrs.url) state.write(node.attrs.url);
  state.closeBlock(node);
};

export default blobEmbed;
