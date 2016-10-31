/**
 * CustomEvent support for IE
 */
window.CustomEvent = window.CustomEvent || function CustomEvent(event, params) {
  const options = params || { bubbles: false, cancelable: false, detail: undefined };
  const evt = document.createEvent('CustomEvent');
  evt.initCustomEvent(event, options.bubbles, options.cancelable, options.detail);
  return evt;
};

window.CustomEvent.prototype = window.CustomEvent.prototype || window.Event.prototype;
