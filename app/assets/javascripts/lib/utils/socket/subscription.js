class Subscription {
  constructor({
    id,
    endpoint,
    data,
    socket,
    callbacks,
  }) {
    this.id = id;
    this.endpoint = endpoint;
    this.data = data;
    this.socket = socket;
    this.updateCallback = callbacks.updateCallback;
    this.errorCallback = callbacks.errorCallback;

    this.setPayload();
    this.setEventNames();
  }

  subscribe() {
    this.socket.emit(this.eventNames.subscribe, this.payload, this.acknowledge);

    this.bindListeners();
  }

  unsubscribe() {
    this.socket.emit(this.eventNames.unsubscribe, this.payload, this.acknowledge);

    this.unbindListeners();
  }

  bindListeners() {
    this.socket.on(this.eventNames.update, this.updateCallback);
    this.socket.on(this.eventNames.error, this.errorCallback);
  }

  unbindListeners() {
    this.socket.removeListener(this.eventNames.update, this.updateCallback);
    this.socket.removeListener(this.eventNames.error, this.errorCallback);
  }

  setPayload() {
    this.payload = {
      id: this.id,
      endpoint: this.endpoint,
      data: this.data,
    };
  }

  setEventNames() {
    this.eventNames = {
      subscribe: `subscribe:${this.endpoint}`,
      unsubscribe: `unsubscribe:${this.endpoint}`,
      update: `update:${this.id}`,
      error: `error:${this.id}`,
    };
  }

  acknowledge(response, ...args) {
    if (response.error) this.errorCallback(response.error, ...args);

    // temporary
    // eslint-disable-next-line no-console
    console.log('ACK', ...args);
  }
}

export default Subscription;
