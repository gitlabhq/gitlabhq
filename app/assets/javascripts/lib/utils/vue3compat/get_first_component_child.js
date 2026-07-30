import Vue from 'vue';

const isVue2 = Vue.version.startsWith('2');

const findComponentProxy = (vnode) => {
  if (!vnode) return null;
  if (vnode.component) return vnode.component.proxy;
  if (!Array.isArray(vnode.children)) return null;

  return vnode.children.reduce((found, child) => found ?? findComponentProxy(child), null);
};

/**
 * Cross-version replacement for `vm.$children[0]`, which is removed under
 * @vue/compat (the INSTANCE_CHILDREN compat feature is disabled).
 *
 * Returns the first component instance rendered by `vm` — for example the
 * BTable inside a GlTable ref, or the root component of a `new Vue()` app.
 *
 * @param {Object} vm - The Vue instance whose first component child to find
 * @returns {Object|null} The first child component instance, if any
 */
export function getFirstComponentChild(vm) {
  if (!vm) return null;

  if (isVue2) {
    return vm.$children[0] ?? null;
  }

  return findComponentProxy(vm.$.subTree);
}
