/**
 * Polyfill
 * @what Element.classList
 * @why In order to align browser features
 * @browsers Internet Explorer 11
 * @see https://caniuse.com/#feat=classlist
 */
import 'classlist-polyfill';

/**
 * Polyfill
 * @what Element.closest
 * @why In order to align browser features
 * @browsers Internet Explorer 11
 * @see https://caniuse.com/#feat=element-closest
 */
Element.prototype.closest =
  Element.prototype.closest ||
  function closest(selector, selectedElement = this) {
    if (!selectedElement) return null;
    return selectedElement.matches(selector)
      ? selectedElement
      : Element.prototype.closest(selector, selectedElement.parentElement);
  };

/**
 * Polyfill
 * @what Element.matches
 * @why In order to align browser features
 * @browsers Internet Explorer 11
 * @see https://caniuse.com/#feat=mdn-api_element_matches
 */
Element.prototype.matches =
  Element.prototype.matches ||
  Element.prototype.matchesSelector ||
  Element.prototype.mozMatchesSelector ||
  Element.prototype.msMatchesSelector ||
  Element.prototype.oMatchesSelector ||
  Element.prototype.webkitMatchesSelector ||
  function matches(selector) {
    const elms = (this.document || this.ownerDocument).querySelectorAll(selector);
    let i = elms.length - 1;
    while (i >= 0 && elms.item(i) !== this) {
      i -= 1;
    }
    return i > -1;
  };

/**
 * Polyfill
 * @what ChildNode.remove, Element.remove, CharacterData.remove, DocumentType.remove
 * @why In order to align browser features
 * @browsers Internet Explorer 11
 * @see https://caniuse.com/#feat=childnode-remove
 *
 * From the polyfill on MDN, https://developer.mozilla.org/en-US/docs/Web/API/ChildNode/remove#Polyfill
 */
(arr => {
  arr.forEach(item => {
    if (Object.prototype.hasOwnProperty.call(item, 'remove')) {
      return;
    }
    Object.defineProperty(item, 'remove', {
      configurable: true,
      enumerable: true,
      writable: true,
      value: function remove() {
        if (this.parentNode !== null) {
          this.parentNode.removeChild(this);
        }
      },
    });
  });
})([Element.prototype, CharacterData.prototype, DocumentType.prototype]);
