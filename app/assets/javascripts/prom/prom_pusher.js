import prom from 'promjs';

const PromPusher = {
  init(opts = {}) {
    this.pushInterval = opts.interval || 15000;
    this.gatewayEndpoint = opts.gatewayEndpoint;

    this.registry = prom();

    this.startInterval();
  },

  startInterval() {
    if (this.timeout) clearTimeout(this.timeout);

    const onSuccess = this.onSuccess.bind(this);
    const onError = this.onError.bind(this);

    this.timeout = setTimeout(() => {
      this.pushMetrics()
        .then(onSuccess, onError)
        .catch(onError);
    }, this.pushInterval);
  },

  pushMetrics() {
    const promise = new Promise((resolve, reject) => {
      const metrics = this.registry.metrics();

      if (!metrics) return reject(new Error('No metrics available'));

      return $.post(this.gatewayEndpoint, metrics)
        .then(resolve, reject)
        .fail(reject);
    });

    return promise;
  },

  onSuccess() {
    this.registry.clear();

    this.startInterval();
  },

  onError(error) {
    // Handle error.
    // Just let sentry catch? Not much we can "handle" here.

    this.startInterval();
  },

  getMetric(type, name, help) {
    return this.registry.get(name) || this.registry.create(type, name, help);
  },
};

export default PromPusher;
