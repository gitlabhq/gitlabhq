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
  const { store: vuexStore, namespace } =
    /** @type {{ store: VuexStore, namespace: string }} */ config;
  const getVuexState = namespace ? () => vuexStore.state[namespace] : () => vuexStore.state;
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
      const [prefixOrName, name] = type.split('/');
      committing = true;
      if (!name && prefixOrName in context.store) {
        context.store[prefixOrName](cloneDeep(payload));
      } else if (prefixOrName === namespace && name in context.store) {
        context.store[name](cloneDeep(payload));
      }
      committing = false;
    },
    { prepend: true },
  );

  context.store.$onAction(({ name, args }) => {
    if (committing) return;
    const mutationName = namespace ? `${namespace}/${name}` : name;
    // eslint-disable-next-line no-underscore-dangle
    if (!(mutationName in vuexStore._mutations)) return;
    committing = true;
    vuexStore.commit(mutationName, ...cloneDeep(args));
    committing = false;
  });
};
