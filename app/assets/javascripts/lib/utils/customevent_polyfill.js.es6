/**
 * CustomEvent support for IE
 */
if (typeof window.CustomEvent !== 'function') {
  window.CustomEvent = function CustomEvent(e, params) {
    const options = params || { bubbles: false, cancelable: false, detail: undefined };
    const evt = document.createEvent('CustomEvent');
    evt.initCustomEvent(e, options.bubbles, options.cancelable, options.detail);
    return evt;
  };
  window.CustomEvent.prototype = window.Event.prototype;
}
