import Vue from 'vue';

/**
 * Vue mount function. This mounts a Vue component at a specific mount point with an optional set
 * of props which can be passed into the function or inferred from `data-` attributes on the target
 * DOM node.
 *
 * @param {string|HTMLElement} target - a selector string or DOM node to use as a mount point
 * @param {Vue} component - a Vue component to mount at the provided DOM node
 * @param {Object} extraProps - properties to pass to the Vue component in addition to those found
 *   in the mound point node's data attribues.
 */

export default function mountComponent(target, component, extraProps = {}) {
  const el = target instanceof HTMLElement ? target : document.querySelector(target);

  if (el == null) {
    if (!target) throw new Error('Invalid mount point provided.');
    throw new Error(`No mount point found matching "${target}"`);
  }

  return new Vue({
    el,
    mounted() {
      setTimeout(() => this.$emit('mounted'));
    },
    render(createElement) {
      return createElement(component, {
        props: { ...el.dataset, ...extraProps },
      });
    },
  });
}
