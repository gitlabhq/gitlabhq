import Vue from 'vue';

/**
 * Returns the root element of the given Vue component.
 *
 * This should *only* be used in existing legacy areas of code where Vue is not
 * in use. For example, as part of the migration strategy defined in
 * https://gitlab.com/groups/gitlab-org/-/epics/7626.
 *
 * @param {Object} Component - The Vue component to render.
 * @param {Object} data - The data object to pass to the render function.
 * @param {string|Array} children - The children to render in the default slot
 *     of the component.
 * @returns {HTMLElement}
 */
export const renderVueComponentForLegacyJS = (Component, data, children) => {
  const vm = new Vue({
    render(h) {
      return h(Component, data, children);
    },
  });

  vm.$mount();

  // Ensure it's rendered
  vm.$forceUpdate();

  const el = vm.$el.cloneNode(true);
  vm.$destroy();

  return el;
};
