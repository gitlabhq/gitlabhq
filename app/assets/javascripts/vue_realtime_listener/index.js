/* eslint-disable no-param-reassign */

((gl) => {
  gl.VueRealtimeListener = (removeIntervals, startIntervals) => {
    const removeAll = () => {
      removeIntervals();
      window.removeEventListener('beforeunload', removeIntervals);
      window.removeEventListener('focus', startIntervals);
      window.removeEventListener('blur', removeIntervals);
      document.removeEventListener('beforeunload', removeAll);
    };

    window.addEventListener('beforeunload', removeIntervals);
    window.addEventListener('focus', startIntervals);
    window.addEventListener('blur', removeIntervals);
    document.addEventListener('beforeunload', removeAll);

    // add removeAll methods to stack
    const stack = gl.VueRealtimeListener.reset;
    gl.VueRealtimeListener.reset = () => {
      gl.VueRealtimeListener.reset = stack;
      removeAll();
      stack();
    };
  };

  // remove all event listeners and intervals
  gl.VueRealtimeListener.reset = () => undefined; // noop
})(window.gl || (window.gl = {}));
