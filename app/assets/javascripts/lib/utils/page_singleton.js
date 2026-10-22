// The registry is global, like `~/lib/utils/observable`, so it is shared even when
// this module is built twice.
const REGISTRY_KEY = Symbol.for('__gitlab_page_singleton__');
if (!globalThis[REGISTRY_KEY]) globalThis[REGISTRY_KEY] = new Map();
const singletons = globalThis[REGISTRY_KEY];

/**
 * Returns the one value for `key` on this page, and calls `create` to make it
 * the first time. Use it for module state that must exist once per page also
 * when the module itself is built once for Vue 2 and once for Vue 3.
 *
 * @param {string} key
 * @param {function(): *} create
 * @returns {*}
 */
export const pageSingleton = (key, create) => {
  if (!singletons.has(key)) singletons.set(key, create());
  return singletons.get(key);
};

/**
 * @param {string} key
 * @returns {void}
 */
export const clearPageSingleton = (key) => {
  singletons.delete(key);
};
