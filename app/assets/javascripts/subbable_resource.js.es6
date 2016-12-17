(() => {
/*
 *   SubbableResource can be extended to provide a pubsub-style service for one-off REST
*   calls. Subscribe by passing a callback or render method you will use to handle responses.
*
*   TODO: Provide support for matchers
 *
* */

  class SubbableResource {
    constructor(resourcePath, test) {
      this.endpoint = resourcePath;
      this.defaultPayload = { url: resourcePath };
      // TODO: Switch to axios.create asap
      this.resource = $.ajax;
      this.subscribers = [];
    }

    extendDefaultPayload(payload) {
      return Object.assign(payload, this.defaultPayload);
    }

    subscribe(callback) {
      this.subscribers.push(callback);
    }

    publish(newResponse) {
      const responseCopy = _.extend({}, newResponse);
      this.subscribers.forEach((fn) => {
        fn(responseCopy);
      });
      return newResponse;
    }

    get(payload) {
      this.extendDefaultPayload(payload);
      return this.resource(payload)
        .then(data => this.publish(data));
    }

    post(payload) {
      this.extendDefaultPayload(payload);
      return this.resource(payload)
        .then(data => this.publish(data));
    }

    put(payload) {
      this.extendDefaultPayload(payload);
      return this.resource(payload)
        .then(data => this.publish(data));
    }

    delete(payload) {
      this.extendDefaultPayload(payload);
      return this.resource(payload)
        .then(data => this.publish(data));
    }
  }

  gl.SubbableResource = SubbableResource;
})(window.gl || (window.gl = {}));
