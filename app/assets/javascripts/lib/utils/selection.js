export const querySelectionClosest = (selector) => {
  const selection = window.getSelection();
  if (selection.rangeCount === 0) return null;

  const el = selection.getRangeAt(0).startContainer;
  const node = el.nodeType === Node.TEXT_NODE ? el.parentNode : el;
  return node.closest(selector);
};
