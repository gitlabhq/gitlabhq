if (typeof window.CustomEvent !== 'function') {
  window.CustomEvent = function CustomEvent(event, params) {
    const evt = document.createEvent('CustomEvent');
    const evtParams = params || { bubbles: false, cancelable: false, detail: undefined };
    evt.initCustomEvent(event, evtParams.bubbles, evtParams.cancelable, evtParams.detail);
    return evt;
  };
  window.CustomEvent.prototype = Event;
}
