export const hasSelection = (tiptapEditor) => {
  const { from, to } = tiptapEditor.state.selection;

  return from < to;
};
