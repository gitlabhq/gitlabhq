import $ from 'jquery';

/**
 * Helper to user bootstrap popover in vue.js.
 * Follow docs for html attributes: https://getbootstrap.com/docs/3.3/javascript/#static-popover
 *
 * @example
 * import popover from 'vue_shared/directives/popover.js';
 * {
 *   directives: [popover]
 * }
 * <a v-popover="{options}">popover</a>
 */
export default {
  bind(el, binding) {
    $(el).popover(binding.value);
  },

  unbind(el) {
    $(el).popover('destroy');
  },
};
