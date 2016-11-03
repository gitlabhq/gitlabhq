//= require vue

((global) => {

  /**
   * Bootstrap tooltips are intialized once per pageload. This directive ensures the text used
   * to populate the tooltip is updated dynamically. The tooltip is initialized by reading the
   * `title` attribute and copying its value to the `data-original-title` attribute for lookup each
   * time the tooltip is shown. Rhe tooltip's `title` is not stored or accessed elsewhere, making
   * it  reasonably safe to write to as needed.
   */

  Vue.directive('tooltip-title', {
    update: function (val) {
      // TODO: When we bump to Vue 2.0, `el` will now be passed to this function
      // TODO: Remove/revise this when we transition away from Bootstrap tooltips

      const updatedValue = val || this.el.getAttribute('title');

      this.el.setAttribute('title', updatedValue);

      this.el.setAttribute('data-original-title', updatedValue);
    },
  });

})(window.gl || (window.gl = {}));
