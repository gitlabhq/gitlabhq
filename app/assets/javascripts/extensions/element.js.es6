/* eslint-disable */
Element.prototype.matches = Element.prototype.matches || Element.prototype.msMatches;

Element.prototype.closest = function closest(selector, selectedElement = this) {
  if (!selectedElement) return;
  return selectedElement.matches(selector) ? selectedElement : Element.prototype.closest(selector, selectedElement.parentElement);
};
