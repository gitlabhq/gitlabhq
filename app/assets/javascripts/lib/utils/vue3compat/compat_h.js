import Vue, { h } from 'vue';
import { toHandlerKey } from './to_handler_key';

const isVue2 = Vue.version.startsWith('2');

const mergeTruthy = (...values) => {
  const present = values.filter(Boolean);

  if (present.length <= 1) {
    return present[0];
  }

  return present;
};

const toVue3Data = ({
  props,
  attrs,
  on,
  nativeOn,
  domProps,

  scopedSlots,
  class: klass,
  staticClass,
  style,
  staticStyle,
  ...rest
} = {}) => {
  const flat = { ...rest, ...attrs, ...props, ...domProps };

  const classValue = mergeTruthy(staticClass, klass);
  if (classValue !== undefined) {
    flat.class = classValue;
  }

  const styleValue = mergeTruthy(staticStyle, style);
  if (styleValue !== undefined) {
    flat.style = styleValue;
  }

  // Vue 2 registers `on` (component-event channel) and `nativeOn` (native
  // DOM channel) independently, so the same event key may carry a handler in
  // both. Vue 3 vnode props accept handler arrays: merge colliding keys the
  // way @vue/compat converts legacy vnode data, instead of letting spread
  // order silently drop the `on` handler.
  [on, nativeOn].forEach((listeners) => {
    Object.entries(listeners || {}).forEach(([event, handler]) => {
      const key = toHandlerKey(event);
      const existing = flat[key];
      if (existing === handler) {
        return;
      }
      flat[key] = existing ? [].concat(existing, handler) : handler;
    });
  });

  return flat;
};

/**
 * Version-agnostic `h` for hand-written render functions built on the
 * Vue 2 vnode-data shape (`{ props, attrs, on, nativeOn, domProps,
 * scopedSlots, class, style, key, ref }`).
 *
 * - On Vue 2, this is exactly `h(tag, data, children)` (the Vue 2.7 named
 *   `h` export, valid inside any render running with an active instance).
 * - On Vue 3 (plain or @vue/compat), the data object is flattened to native
 *   vnode props the way @vue/compat converts legacy data: `attrs`/`props`/
 *   `domProps` merge into flat props, `on`/`nativeOn` become camelized
 *   `onX` handlers (an event key present in both channels keeps both
 *   handlers, merged into an array), `class`/`staticClass` and
 *   `style`/`staticStyle` merge,
 *   and `scopedSlots` (plus any non-slot-object children of a component)
 *   become the slots argument.
 *
 * Callers should take no `h` parameter (plain Vue 3 does not pass one) and
 * wrap their component with normalizeRender (see ./normalize_render.js) so
 * @vue/compat does not misclassify the zero-arg render as a legacy Vue 2
 * render function.
 *
 * @param {string|Object} tag - Element tag or component.
 * @param {Object} [data] - Vue 2 vnode data object.
 * @param {string|Array|Object|Function} [children] - Children (elements) or
 *     default slot content (components).
 * @returns {Object} A vnode of the running Vue runtime.
 */
export function compatH(tag, data = undefined, children = undefined) {
  if (isVue2) {
    return children === undefined ? h(tag, data) : h(tag, data, children);
  }

  const flat = data ? toVue3Data(data) : data;
  const isComponent = typeof tag !== 'string';

  let slotsOrChildren = children;
  if (isComponent) {
    const scopedSlots = data?.scopedSlots;
    if (children != null && !Array.isArray(children) && typeof children === 'object') {
      // Already a slots object.
      slotsOrChildren = { ...children, ...scopedSlots };
    } else if (children != null) {
      // Wrap raw children in a default slot function: Vue 3 warns about
      // non-function children for components.
      slotsOrChildren = { default: () => children, ...scopedSlots };
    } else if (scopedSlots) {
      slotsOrChildren = { ...scopedSlots };
    }
  }

  return slotsOrChildren === undefined ? h(tag, flat) : h(tag, flat, slotsOrChildren);
}
