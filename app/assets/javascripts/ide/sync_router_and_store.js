/**
 * This method adds listeners to the given router and store and syncs their state with eachother
 *
 * ### Why?
 *
 * Previously the IDE had a circular dependency between a singleton router and a singleton store.
 * This causes some integration testing headaches...
 *
 * At the time, the most effecient way to break this ciruclar dependency was to:
 *
 * - Replace the router with a factory function that receives a store reference
 * - Have the store write to a certain state that can be watched by the router
 *
 * Hence... This helper function...
 */
export const syncRouterAndStore = (router, store) => {
  const disposables = [];

  let currentPath = '';

  // sync store to router
  disposables.push(
    store.watch(
      (state) => state.router.fullPath,
      (fullPath) => {
        if (currentPath === fullPath) {
          return;
        }

        currentPath = fullPath;

        router.push(fullPath);
      },
    ),
  );

  // sync router to store
  disposables.push(
    router.afterEach((to) => {
      if (currentPath === to.fullPath) {
        return;
      }

      currentPath = to.fullPath;
      store.dispatch('router/push', currentPath, { root: true });
    }),
  );

  const unsync = () => {
    disposables.forEach((fn) => fn());
  };

  return unsync;
};
