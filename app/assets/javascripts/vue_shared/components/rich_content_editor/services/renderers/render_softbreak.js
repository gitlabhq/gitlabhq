const canRender = (node) => ['emph', 'strong'].includes(node.parent?.type);
const render = () => ({
  type: 'text',
  content: ' ',
});

export default { canRender, render };
