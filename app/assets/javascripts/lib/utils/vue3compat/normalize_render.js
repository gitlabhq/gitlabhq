import Vue from 'vue';

export function normalizeRender(originalComponent) {
  if (Vue.version.startsWith('2')) {
    return originalComponent;
  }

  return {
    ...originalComponent,
    render(...args) {
      const result = originalComponent.render.call(this, ...args);
      if (Array.isArray(result) && result.length === 1) {
        return result[0];
      }

      return result;
    },
  };
}

/**
 * Version-agnostic slot lookup for hand-written render functions.
 *
 * Vue 2 exposes every slot (scoped or not) as a function on
 * `vm.$scopedSlots`; Vue 3 exposes them as functions on `vm.$slots`.
 * Returns the slot function, or undefined when the slot was not provided.
 *
 * @param {Object} vm - The component instance (`this` inside `render`).
 * @param {string} [name] - The slot name.
 * @returns {Function|undefined}
 */
export function getSlotFunction(vm, name = 'default') {
  // Vue 2 and @vue/compat expose every slot as a function on $scopedSlots;
  // plain Vue 3 has no $scopedSlots and exposes them on $slots.
  return vm.$scopedSlots?.[name] ?? vm.$slots?.[name];
}
