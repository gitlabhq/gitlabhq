//= require vue
//= require vue-resource

((global) => {
/*
*   SubbableResource can be extended to provide a pubsub-style service for one-off REST
*   calls. Subscribe by passing a callback or render method you will use to handle responses.
 *
* */

  class SubbableResource {
    constructor(resourcePath) {
      this.endpoint = resourcePath;
      // TODO: Switch to axios.create
      this.resource = $.ajax;
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

    get(data) {
      return this.resource(data)
        .then(data => this.publish(data));
    }

    post(data) {
      return this.resource(data)
        .then(data => this.publish(data));
    }

    put(data) {
      return this.resource(data)
        .then(data => this.publish(data));
    }

    delete(data) {
      return this.resource(data)
        .then(data => this.publish(data));
    }
  }

  gl.SubbableResource = SubbableResource;
})(window.gl || (window.gl = {}));
