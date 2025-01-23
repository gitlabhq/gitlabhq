/**
 * @typedef {import('pinia').PiniaPluginContext} PiniaPluginContext
 * @typedef {import('vuex').Store} VuexStore
 */

/**
 * @param {PiniaPluginContext} context
 */
// never use this for regular stores, only use this if you have circular dependencies during Vuex migration
export const globalAccessorPlugin = (context) => {
  // eslint-disable-next-line no-param-reassign
  context.store.tryStore = (storeName) => {
    // eslint-disable-next-line no-underscore-dangle
    const anotherStore = context.pinia._s.get(storeName);

    if (!anotherStore) {
      const hookName = `use${storeName.charAt(0).toUpperCase() + storeName.slice(1)}`;
      throw new ReferenceError(
        `Store '${storeName}' doesn't exist. Ensure you have called ${hookName}.`,
      );
    }

    return anotherStore;
  };
};

/**
 * @param {PiniaPluginContext} context
 */
// use this only for component migration
export const syncWithVuex = (context) => {
  const config = context.options.syncWith;
  if (!config) {
    return;
  }
  const { store: vuexStore, namespace } =
    /** @type {{ store: VuexStore, namespace: string }} */ config;
  const getVuexState = namespace ? () => vuexStore.state[namespace] : () => vuexStore.state;
  context.store.$patch(getVuexState());
  vuexStore.subscribe(
    () => {
      context.store.$patch(getVuexState());
    },
    { prepend: true },
  );
  context.store.$subscribe(
    namespace
      ? () => {
          vuexStore.state[namespace] = context.store.$state;
        }
      : () => {
          vuexStore.replaceState(context.store.$state);
        },
    { flush: 'sync' },
  );
};
