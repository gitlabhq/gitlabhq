import socketIO from 'socket.io-client';
import Socket from 'socket.io-client/lib/socket';
import Subscription from './subscription';
import SubscriptionStore from './subscription_store';

const SocketManager = {
  socketPath: '',
  socket: {},
  store: SubscriptionStore,
  subscriptionsCount: 0,

  init(socketPath) {
    this.socketPath = socketPath;

    this.removeAll();
  },

  connect() {
    if (this.socket instanceof Socket) return Promise.resolve();

    return new Promise((resolve, reject) => {
      this.socket = socketIO(this.socketPath);

      this.socket.on('connect', resolve);
      this.socket.on('connect_error', reject);
      this.socket.on('connect_timeout', reject);
    });
  },

  subscribe(endpointOrSubscription, data, callbacks) {
    this.connect().then(() => {
      const subscription = this.getSubscription(endpointOrSubscription, data, callbacks);

      subscription.subscribe();

      return subscription;
    }).catch((error) => {
      // temporary
      // eslint-disable-next-line no-console
      console.log('connect error', error);
    });
  },

  remove(subscription) {
    subscription.unsubscribe();

    this.store.remove(subscription);
  },

  unsubscribeAll() {
    const subscriptions = this.store.getAll();

    if (!subscriptions) return;

    subscriptions.forEach(subscription => subscription.unsubscribe());
  },

  subscribeAll() {
    const subscriptions = this.store.getAll();

    if (!subscriptions) return;

    subscriptions.forEach(subscription => subscription.subscribe());
  },

  removeAll() {
    this.unsubscribeAll();
    this.store.removeAll();
  },

  getSubscription(endpointOrSubscription, data, callbacks) {
    let subscription;

    if (endpointOrSubscription instanceof Subscription) {
      subscription = endpointOrSubscription;
    } else {
      subscription = this.createSubscription({
        endpoint: endpointOrSubscription,
        data,
        callbacks,
      });
    }

    return subscription;
  },

  createSubscription({
    endpoint,
    data,
    callbacks,
  }) {
    this.subscriptionsCount += 1;

    const subscription = new Subscription({
      endpoint,
      data,
      callbacks,
      socket: this.socket,
      id: this.subscriptionsCount,
    });

    this.store.add(subscription);

    return subscription;
  },
};

export default SocketManager;
