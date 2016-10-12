//= require vue
//= require vue-resource

(() => {
/*
*   SubbableResource can be extended to provide a pubsub-style service for one-off REST
*   calls and/or ongoing polling of a resource.  It is usable by both Vue-ized and
*   non-Vue-ized components.
*
*   Subscribe by passing a callback or render method you will use to handle responses.
*
*   To test manually, add the following to the javascript listed in issuable/sidebar.js
*   gl.IssuableResource = new gl.createSubbableResource({
      resourcePath: '#{issuable_json_path(issuable)}',
      pollingConfig : {
        startingInterval: 1000,
        maxInterval: 10000,
        incrementByFactorOf: 2,
        logIterations: true,
        lazyStart: false,
        delayStartBy: 0
      }
    });
 *
* */

  class SubbableResource {
    constructor({ resourcePath, pollingConfig }) {
      this.resource = Vue.resource(resourcePath);
      this.subscribers = [];
      this.initPolling(pollingConfig);
    }

    initPolling(pollingConfig) {
      if (pollingConfig) {
        const ammendedConfig = pollingConfig;
        ammendedConfig.callback = this.get.bind(this);
        this.smartInterval = new gl.SmartInterval(ammendedConfig);
      }
    }

    /* public */
    subscribe(callback) {
      this.subscribers.push(callback);
    }

    publish(newResponse) {
      const responseCopy = _.extend({}, newResponse);
      this.subscribers.forEach((fn) => {
        fn(responseCopy);
      });
    }

    get() {
      return this.resource.get()
        .then(res => this.publish(res));
    }

    save(payload) {
      return this.resource.save(payload)
        .then(res => this.publish(res));
    }

    update(payload) {
      return this.resource.update(payload)
        .then(res => this.publish(res));
    }

    remove(payload) {
      return this.resource.remove(payload)
        .then(res => this.publish(res));
    }
  }

/*
 * SubbableResourceFactory is a gatekeeper for SubbableResources. It allows us to ensure
 * that resources for a given endpoint/resource are only created once.
 *
  */

  class SubbableResourceFactory {
    constructor() {
      this.resources = [];
    }

    create(resourceConfig) {
      // ensure only one resource per endpoint
      const existingResource = this.findExistingResource(resourceConfig.resourcePath);

      if (existingResource) {
        return existingResource;
      }

      const newResource = new SubbableResource(resourceConfig);

      this.resources.push(newResource);

      return newResource;
    }

    findExistingResource(resourcePath) {
      return this.resources.filter(resource => resource.path === resourcePath)[0];
    }
  }

  const resourceFactory = new SubbableResourceFactory();

  // only expose creation method
  gl.createSubbableResource = resourceConfig => resourceFactory.create(resourceConfig);
})(window.gl || (window.gl = {}));
