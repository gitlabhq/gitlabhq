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
