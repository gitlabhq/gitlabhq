const SocketStore = {
  subscriptions: {},

  add(subscription) {
    this.subscriptions[subscription.id] = subscription;

    return subscription;
  },

  remove(subscription) {
    delete this.subscriptions[subscription.id];
  },

  get(subscriptionID) {
    return this.subscriptions[subscriptionID];
  },

  getAll() {
    Object.values(this.subscriptions);
  },

  removeAll() {
    this.subscriptions = {};
  },
};

export default SocketStore;
