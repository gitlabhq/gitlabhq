export default (removeIntervals, startIntervals) => {
  window.removeEventListener('focus', startIntervals);
  window.removeEventListener('blur', removeIntervals);
  window.removeEventListener('onbeforeload', removeIntervals);

  window.addEventListener('focus', startIntervals);
  window.addEventListener('blur', removeIntervals);
  window.addEventListener('onbeforeload', removeIntervals);
};
