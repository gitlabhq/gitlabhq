export const hasSelection = (tiptapEditor) => {
  const { from, to } = tiptapEditor.state.selection;

  return from < to;
};

export const clamp = (n, min, max) => Math.max(Math.min(n, max), min);
