export const clearDomElement = el => {
  if (!el || !el.firstChild) return;

  while (el.firstChild) {
    el.removeChild(el.firstChild);
  }
};

export default () => ({
  clearDomElement,
});
