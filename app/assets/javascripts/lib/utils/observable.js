import Vue from 'vue';

const REGISTRY_KEY = Symbol.for('__gitlab_shared_observable__');
if (!globalThis[REGISTRY_KEY]) globalThis[REGISTRY_KEY] = new Map();

/**
 * Creates a shared observable that stays synchronized across Vue 2 and Vue 3
 * module boundaries in the hybrid infection system.
 *
 * In the infection system, modules imported by both Vue 2 and Vue 3 contexts
 * get duplicated. Using `Vue.observable()` in such modules creates separate
 * reactive objects per copy — state changes in one are invisible to the other.
 *
 * This utility solves the problem by:
 * 1. Storing a single canonical state in a global registry (via Symbol.for)
 * 2. Creating a per-Vue-context reactive mirror via Vue.observable()
 * 3. Returning a Proxy that syncs writes to ALL mirrors across Vue versions
 *
 * @param {string} key Unique identifier for this shared state
 * @param {object} defaults Initial state (only used on the first call for a given key)
 * @returns {Proxy} Reactive proxy synchronized across Vue versions
 */
export function observable(key, defaults) {
  const registry = globalThis[REGISTRY_KEY];

  if (!registry.has(key)) {
    const source = Object.defineProperties({}, Object.getOwnPropertyDescriptors(defaults));
    registry.set(key, { source, mirrors: [] });
  }

  const { source, mirrors } = registry.get(key);

  const mirrorObj = Object.defineProperties({}, Object.getOwnPropertyDescriptors(source));
  // eslint-disable-next-line no-restricted-properties
  const mirror = Vue.observable(mirrorObj);
  mirrors.push(mirror);

  return new Proxy(mirror, {
    get(target, prop, receiver) {
      return Reflect.get(target, prop, receiver);
    },
    set(_target, prop, value) {
      const desc = Object.getOwnPropertyDescriptor(source, prop);
      if (!desc || !desc.get) {
        source[prop] = value;
      }
      for (const m of mirrors) {
        m[prop] = value;
      }
      return true;
    },
    deleteProperty(_target, prop) {
      delete source[prop];
      for (const m of mirrors) {
        delete m[prop];
      }
      return true;
    },
  });
}

/**
 * Resets a shared observable entry, removing it from the global registry.
 * The next call to `observable()` with the same key will create fresh state.
 *
 * Primarily used in tests to prevent state leaking between test cases.
 *
 * @param {string} key The key to reset
 */
export function resetObservable(key) {
  const registry = globalThis[REGISTRY_KEY];
  if (registry) registry.delete(key);
}
