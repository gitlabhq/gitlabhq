/* eslint-disable no-param-reassign */

((gl) => {
  gl.VueRealtimeListener = (removeIntervals, startIntervals) => {
    const removeAll = () => {
      removeIntervals();
      window.removeEventListener('beforeunload', removeIntervals);
      window.removeEventListener('focus', startIntervals);
      window.removeEventListener('blur', removeIntervals);
      document.removeEventListener('page:fetch', removeAll);
    };

    window.addEventListener('beforeunload', removeIntervals);
    window.addEventListener('focus', startIntervals);
    window.addEventListener('blur', removeIntervals);
    document.addEventListener('page:fetch', removeAll);
  };
})(window.gl || (window.gl = {}));
