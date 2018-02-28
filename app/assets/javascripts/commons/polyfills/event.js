/**
 * Polyfill for IE11 support.
 * new Event() is not supported by IE11.
 * Although `initEvent` is deprecated for modern browsers it is the one supported by IE
 */
if (typeof window.Event !== 'function') {
  window.Event = function Event(event, params) {
    const evt = document.createEvent('Event');
    const evtParams = {
      bubbles: false,
      cancelable: false,
      ...params,
    };
    evt.initEvent(event, evtParams.bubbles, evtParams.cancelable);
    return evt;
  };
  window.Event.prototype = Event;
}
