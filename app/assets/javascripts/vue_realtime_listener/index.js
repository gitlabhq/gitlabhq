const VueRealtimeListener = (removeIntervals, startIntervals) => {
  const removeAll = () => {
    window.removeEventListener('beforeunload', removeIntervals);
    window.removeEventListener('focus', startIntervals);
    window.removeEventListener('blur', removeIntervals);
  };

  window.addEventListener('beforeunload', removeIntervals);
  window.addEventListener('focus', startIntervals);
  window.addEventListener('blur', removeIntervals);

  // add removeAll methods to stack
  const stack = VueRealtimeListener.reset;
  VueRealtimeListener.reset = () => {
    VueRealtimeListener.reset = stack;
    removeAll();
    stack();
  };
};

// remove all event listeners and intervals
VueRealtimeListener.reset = () => undefined; // noop

module.exports = VueRealtimeListener;
