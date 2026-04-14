/**
 * Creates a proxy that overrides specific properties on a reactive object
 * without breaking its reactivity. Unlike Object.assign or spread, property
 * reads and writes for non-overridden keys pass through to the original
 * reactive target, preserving Vue's change tracking.
 *
 * @template {Object} T
 * @template {Partial<T>} O
 * @param {T} target - The original reactive object.
 * @param {O} overrides - Key-value pairs to override on the proxy.
 * @returns {T}
 */
export function reactiveOverride(target, overrides) {
  return new Proxy(target, {
    get(t, prop) {
      if (Object.hasOwn(overrides, prop)) return overrides[prop];
      return Reflect.get(t, prop);
    },
  });
}
