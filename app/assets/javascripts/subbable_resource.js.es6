(() => {
/*
 *   SubbableResource can be extended to provide a pubsub-style service for one-off REST
*   calls. Subscribe by passing a callback or render method you will use to handle responses.
*
*   TODO: Provide support for matchers
 *
* */

  class SubbableResource {
    constructor(resourcePath) {
      this.endpoint = resourcePath;
      // TODO: Switch to axios.create asap
      this.resource = Vue.resource(resourcePath);
      this.subscribers = [];
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
      return this.resource.get(payload)
        .then(data => this.publish(data));
    }

    save(payload) {
      return this.resource.save(payload)
        .then(data => this.publish(data));
    }

    update(payload) {
      return this.resource.update(payload)
        .then(data => this.publish(data));
    }

    remove(payload) {
      return this.resource.remove(payload)
        .then(data => this.publish(data));
    }
  }

  gl.SubbableResource = SubbableResource;
})(window.gl || (window.gl = {}));
