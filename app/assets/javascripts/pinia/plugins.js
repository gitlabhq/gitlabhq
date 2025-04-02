import { cloneDeep, isEqual } from 'lodash';

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
  const {
    store: vuexStore,
    name: vuexName,
    namespaced,
  } = /** @type {{ store: VuexStore, [name]: string, [namespaced]: boolean }} */ config;
  const getVuexState = vuexName ? () => vuexStore.state[vuexName] : () => vuexStore.state;
  if (!isEqual(context.store.$state, getVuexState())) {
    Object.entries(getVuexState()).forEach(([key, value]) => {
      // we can't use store.$patch here because it will merge state, but we need to overwrite it
      // eslint-disable-next-line no-param-reassign
      context.store[key] = cloneDeep(value);
    });
  }

  let committing = false;

  vuexStore.subscribe(
    (mutation) => {
      if (committing) return;
      const { payload, type } = mutation;
      const [prefixOrName, mutationName] = type.split('/');
      committing = true;
      if (!mutationName && prefixOrName in context.store) {
        context.store[prefixOrName](cloneDeep(payload));
      } else if (prefixOrName === vuexName && mutationName in context.store) {
        context.store[mutationName](cloneDeep(payload));
      }
      committing = false;
    },
    { prepend: true },
  );

  context.store.$onAction(({ name: mutationName, args }) => {
    if (committing) return;
    const fullMutationName = namespaced ? `${vuexName}/${mutationName}` : mutationName;
    // eslint-disable-next-line no-underscore-dangle
    if (!(fullMutationName in vuexStore._mutations)) return;
    committing = true;
    vuexStore.commit(fullMutationName, ...cloneDeep(args));
    committing = false;
  });
};
