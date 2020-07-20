/**
 * Polyfill
 * @what requestIdleCallback
 * @why To align browser features
 * @browsers Safari (all versions)
 * @see https://caniuse.com/#feat=requestidlecallback
 */
window.requestIdleCallback =
  window.requestIdleCallback ||
  function requestShim(cb) {
    const start = Date.now();
    return setTimeout(() => {
      cb({
        didTimeout: false,
        timeRemaining: () => Math.max(0, 50 - (Date.now() - start)),
      });
    }, 1);
  };

window.cancelIdleCallback =
  window.cancelIdleCallback ||
  function cancelShim(id) {
    clearTimeout(id);
  };
