/* global Element */
/* eslint-disable consistent-return, max-len */

Element.prototype.matches = Element.prototype.matches || Element.prototype.msMatchesSelector;

Element.prototype.closest = function closest(selector, selectedElement = this) {
  if (!selectedElement) return;
  return selectedElement.matches(selector) ? selectedElement : Element.prototype.closest(selector, selectedElement.parentElement);
};
