/* global Element */
/* eslint-disable consistent-return, max-len, no-empty, func-names */

Element.prototype.closest = Element.prototype.closest || function closest(selector, selectedElement = this) {
  if (!selectedElement) return;
  return selectedElement.matches(selector) ? selectedElement : Element.prototype.closest(selector, selectedElement.parentElement);
};

Element.prototype.matches = Element.prototype.matches ||
  Element.prototype.matchesSelector ||
  Element.prototype.mozMatchesSelector ||
  Element.prototype.msMatchesSelector ||
  Element.prototype.oMatchesSelector ||
  Element.prototype.webkitMatchesSelector ||
  function (s) {
    const matches = (this.document || this.ownerDocument).querySelectorAll(s);
    let i = matches.length - 1;
    while (i >= 0 && matches.item(i) !== this) { i -= 1; }
    return i > -1;
  };
