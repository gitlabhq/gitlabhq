//= require vue

((global) => {

  /**
   * This directive ensures the text used to populate a Bootstrap tooltip is
   * updated dynamically. The tooltip's `title` is not stored or accessed
   * elsewhere, making it reasonably safe to write to as needed.
   */

  Vue.directive('tooltip-title', {
    update(el, binding) {
      const titleInitAttr = 'title';
      const titleStoreAttr = 'data-original-title';
        
      const updatedValue = binding.value || el.getAttribute(titleInitAttr);

      el.setAttribute(titleInitAttr, updatedValue);
      el.setAttribute(titleStoreAttr, updatedValue);
    },
  });

})(window.gl || (window.gl = {}));
