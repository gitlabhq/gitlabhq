export const keyboardDownEvent = (code, metaKey = false, ctrlKey = false) => {
  const e = new CustomEvent('keydown');

  e.keyCode = code;
  e.metaKey = metaKey;
  e.ctrlKey = ctrlKey;

  return e;
};
