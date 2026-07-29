export const createSubscriptionsCollection = () => {
  const subscriptions = new Map();

  return {
    syncSubscriptions(ids, factory) {
      const desiredSet = new Set(ids);
      for (const [id, unsubscribe] of subscriptions) {
        if (!desiredSet.has(id)) {
          unsubscribe();
          subscriptions.delete(id);
        }
      }
      for (const id of ids) {
        if (!subscriptions.has(id)) {
          const unsubscribe = factory(id);
          subscriptions.set(id, unsubscribe);
        }
      }
    },
    unsubscribeAll() {
      for (const unsubscribe of subscriptions.values()) {
        unsubscribe();
      }
      subscriptions.clear();
    },
  };
};
