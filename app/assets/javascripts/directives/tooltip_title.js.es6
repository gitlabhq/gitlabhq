//= require vue

(() => {
  /**
   * This directive ensures the text used to populate a Bootstrap tooltip is
   * updated dynamically. The tooltip's `title` is not stored or accessed
   * elsewhere, making it reasonably safe to write to as needed.
   */

  Vue.directive('tooltip-title', {
    update(el, binding) {
      const updatedValue = binding.value || el.getAttribute('title');

      el.setAttribute('title', updatedValue);
      el.setAttribute('data-original-title', updatedValue);
    },
  });
})(window.gl || (window.gl = {}));
