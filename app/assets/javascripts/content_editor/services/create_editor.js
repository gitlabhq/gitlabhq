const createEditor = async ({ content }) => {
  const { Editor } = await import(/* webpackChunkName: 'tiptap' */ 'tiptap');
  const { Bold, Code } = await import(/* webpackChunkName: 'tiptap' */ 'tiptap-extensions');

  return new Editor({
    extensions: [new Bold(), new Code()],
    content,
  });
};

export default createEditor;
