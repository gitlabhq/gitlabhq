/**
 * Polyfill
 * @what NodeList.forEach
 * @why To align browser support
 * @browsers Internet Explorer 11
 * @see https://caniuse.com/#feat=mdn-api_nodelist_foreach
 */
if (window.NodeList && !NodeList.prototype.forEach) {
  NodeList.prototype.forEach = function forEach(callback, thisArg = window) {
    for (let i = 0; i < this.length; i += 1) {
      callback.call(thisArg, this[i], i, this);
    }
  };
}
