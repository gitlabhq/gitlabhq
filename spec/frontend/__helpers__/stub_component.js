/**
 * Returns a new object with keys pointing to stubbed methods
 *
 * This is helpful for stubbing components like GlModal where it's supported
 * in the API to call `.show()` and `.hide()` ([Bootstrap Vue docs][1]).
 *
 * [1]: https://bootstrap-vue.org/docs/components/modal#using-show-hide-and-toggle-component-methods
 *
 * @param {Object} methods - Object whose keys will be in the returned object.
 */
const createStubbedMethods = (methods = {}) => {
  if (!methods) {
    return {};
  }

  return Object.keys(methods).reduce(
    (acc, key) =>
      Object.assign(acc, {
        [key]: () => {},
      }),
    {},
  );
};

export const RENDER_ALL_SLOTS_TEMPLATE = `<div>
  <template v-for="(_, name) in $scopedSlots">
    <div :data-testid="'slot-' + name">
      <slot :name="name" />
    </div>
  </template>
</div>`;

export function stubComponent(Component, options = {}) {
  return {
    name: Component.name,
    props: Component.props,
    model: Component.model,
    methods: createStubbedMethods(Component.methods),
    // Do not render any slots/scoped slots except default
    // This differs from VTU behavior which renders all slots
    template: '<div><slot></slot></div>',
    // allows wrapper.findComponent(Component) to work for stub
    $_vueTestUtils_original: Component,
    // @vue/compat misclassifies any render with fewer than 2 parameters as a
    // legacy Vue 2 render, so callers overriding `render` below (commonly
    // zero-arg renders reading this.$scopedSlots) warn RENDER_FUNCTION once
    // per (anonymous) stub instance. 'suppress-warning' rather than `false`:
    // the compat feature must stay enabled so legacy reads like $scopedSlots
    // and the vnode-array $slots shape keep working inside those renders.
    // INSTANCE_SCOPED_SLOTS stays enabled the same way: the
    // RENDER_ALL_SLOTS_TEMPLATE above iterates $scopedSlots, which is the
    // only version-agnostic function-shaped slot map available to a stub
    // template on both runtimes. Inert under Vue 2; per-component
    // compatConfig wins over the global key configuration in
    // compat_config.js.
    compatConfig: {
      RENDER_FUNCTION: 'suppress-warning',
      INSTANCE_SCOPED_SLOTS: 'suppress-warning',
    },
    ...options,
  };
}
