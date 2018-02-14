import Vue from 'vue';

/**
 * This mounts a Vue component to a specific DOM node which is provided as either a string or an
 * HTMLElement. Its props are inferred from the node's `data-` attributes and additional props can
 * be passed as an argument to this function. Props passed to this function will override props of
 * the same name found among the target's data attributes.
 *
 * @param component - a Vue component to mount
 * @param el - a selector string or DOM node to use as a mount point
 * @param props - additional properties to pass to the Vue component
 */

export default function mountComponent(component, el = null, propsData = {}) {
  const Component = Vue.extend(component);
  if (el) {
    const target = el instanceof HTMLElement ? el : document.querySelector(el);
    if (target == null) throw new Error(`No node found matching "${el}"`);
    if (target.dataset) Object.assign(propsData, target.dataset, propsData);
  }
  return new Component({ el, propsData });
}
