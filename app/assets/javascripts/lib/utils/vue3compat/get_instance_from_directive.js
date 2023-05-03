// See https://v3-migration.vuejs.org/breaking-changes/custom-directives.html#edge-case-accessing-the-component-instance
export function getInstanceFromDirective({ binding, vnode }) {
  if (binding.instance) {
    // this is Vue.js 3, even in compat mode
    return binding.instance;
  }

  return vnode.context;
}
