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
  };
})(window.gl || (window.gl = {}));
