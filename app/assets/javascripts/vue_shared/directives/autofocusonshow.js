/**
 * Input/Textarea Autofocus Directive for Vue
 */
export default {
  /**
   * Set focus when element is rendered, but
   * is not visible, using IntersectionObserver
   *
   * @param {Element} el Target element
   */
  inserted(el) {
    if ('IntersectionObserver' in window) {
      // Element visibility is dynamic, so we attach observer
      el.visibilityObserver = new IntersectionObserver((entries) => {
        entries.forEach((entry) => {
          // Combining `intersectionRatio > 0` and
          // element's `offsetParent` presence will
          // deteremine if element is truely visible
          if (entry.intersectionRatio > 0 && entry.target.offsetParent) {
            entry.target.focus();
          }
        });
      });

      // Bind the observer.
      el.visibilityObserver.observe(el, { root: document.documentElement });
    }
  },
  /**
   * Detach observer on unbind hook.
   *
   * @param {Element} el Target element
   */
  unbind(el) {
    if (el.visibilityObserver) {
      el.visibilityObserver.disconnect();
    }
  },
};
