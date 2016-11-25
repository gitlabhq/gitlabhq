/* global Element */
/* eslint-disable consistent-return, max-len */

Element.prototype.closest = Element.prototype.closest || function closest(selector, selectedElement = this) {
  if (!selectedElement) return;
  return selectedElement.matches(selector) ? selectedElement : Element.prototype.closest(selector, selectedElement.parentElement);
};

/* eslint-disable */
/**
 * .matches polyfill from mdn
 * https://developer.mozilla.org/en-US/docs/Web/API/Element/matches
 *
 * .matches is used in our code.
 * In order to run the tests in Phantomjs we need this polyfill
 */
if (!Element.prototype.matches) {
  Element.prototype.matches =
      Element.prototype.matchesSelector ||
      Element.prototype.mozMatchesSelector ||
      Element.prototype.msMatchesSelector ||
      Element.prototype.oMatchesSelector ||
      Element.prototype.webkitMatchesSelector ||
      function (s) {
        var matches = (this.document || this.ownerDocument).querySelectorAll(s),
          i = matches.length;
        while (--i >= 0 && matches.item(i) !== this) {}
        return i > -1;
      };
}
