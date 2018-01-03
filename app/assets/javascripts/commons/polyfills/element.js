Element.prototype.closest = Element.prototype.closest ||
  function closest(selector, selectedElement = this) {
    if (!selectedElement) return null;
    return selectedElement.matches(selector) ?
      selectedElement :
      Element.prototype.closest(selector, selectedElement.parentElement);
  };

Element.prototype.matches = Element.prototype.matches ||
  Element.prototype.matchesSelector ||
  Element.prototype.mozMatchesSelector ||
  Element.prototype.msMatchesSelector ||
  Element.prototype.oMatchesSelector ||
  Element.prototype.webkitMatchesSelector ||
  function matches(selector) {
    const elms = (this.document || this.ownerDocument).querySelectorAll(selector);
    let i = elms.length - 1;
    while (i >= 0 && elms.item(i) !== this) { i -= 1; }
    return i > -1;
  };
