//= require vue
//= require vue-resource

((global) => {

/*
*   SubbableResource can be extended to provide a pubsub-style service sending and receiving updates for
*   a model and propagating changes to subscribers throughout the page. It is usable by both Vue-ized and
*   non-Vue-ized components.
*
*   Subscribe by passing a property you want to be notified of updates to, and pass
*   a callback or render method you will use to render your component's updated state.
*
*   JQuery usage:

    class IssuableAssigneeComponent {
      constructor() {
        this.$elem = $('#assignee');
        gl.IssuableResource.subscribe('assignee_id', (newState) => {
          this.renderState(newState);
        });
      }

      renderState(issuable) {
        this.$elem.val(issuable.assignee_id);
      }
    }

   Vue usage:

    const app = new Vue({
      data: {
        assignee_id: ''
      },
      ready: function() {
        gl.IssuableResource.subscribe('assignee_id', (newState) => {
          this.assignee_id = newState.assignee_id;
        });
      }
    });

* */

  class SubbableResource {
    constructor({ path, data, pollCfg }) {
      this.resource = Vue.resource(path);
      this.data = JSON.parse(data);
      this.subscribers = {};
      this.state = {
        loading: false
      };
      this.init(pollCfg);
    }
    /* private methods */

    init(pollCfg) {
      const preppedCfg = _.extend(pollCfg, {
        callback: this.getResource.bind(this)
      });
      this.interval = new global.SmartInterval(preppedCfg);
    }

    publish(diff) {
      // prevent subscribers mutating state
      const stateCopy = _.extend({}, this.data);
      for (let key in diff) {
        const hasSubscribers = this.subscribers.hasOwnProperty(key);
        if (hasSubscribers) {
          this.subscribers[key].forEach((fn) => {
            fn(stateCopy);
          });
        }
      }
    }

    addSubscriber(prop, callback) {
      const isNewProp = !this.subscribers.hasOwnProperty(prop);
      if (isNewProp) this.subscribers[prop] = [];
      this.subscribers[prop].push(callback);
    }

    updateState(res) {
      const diff = {};
      if (res.updated_at !== this.data.updated_at) {
        for (let key in res) {
          const val = res[key];
          if (this.data[key] !== val) diff[key] = val;
        }
        this.data = _.extend(this.data, diff);
      }
      this.state.loading = false;
      return diff;
    }

    /* public methods */

    subscribe(propToWatch, callback) {
      this.addSubscriber(propToWatch, callback);
    }

    getResource() {
      if (this.state.loading && this.subscribers.length) {
        return;
      }
      this.state.loading = true;
      return this.resource.get()
        .then((res) => this.updateState(res.data))
        .then((newState) => this.publish(newState));
    }

    // The following are only stubs. They would be used to provide DRY
    // access to a remote resource used/modified by multiple components

    postResource(payload) {
      this.resource.post(payload)
        .then((res) => this.updateState(payload))
        .then((newState) => this.publish(newState));
    }

    putResource(payload) {
      this.resource.put(state)
        .then((res) => this.updateState(payload))
        .then((newState) => this.publish(newState));
    }

    deleteResource(payload) {
      this.resource.delete()
        .then((res) => this.updateState(payload))
        .then((newState) => this.publish(newState));
    }
  }

/*
 * SubbableResourceFactory is a gatekeeper for SubbableResources. It allows us to ensure that
 * that resources for a given path are only created once. In time, it may provide additional
 * opportunities for resource configuration.

  Usage:

  gl.IssuableResource = createSubbableResource({
    path: issuable_path_to_json,
    data: issuable,
    pollInterval: 15000,
  });

  */

  class SubbableResourceFactory {
    constructor() {
      this.resources = [];
    }
    create(opts) {
      // ensure only one resource per endpoint
      const existingResource = this.existingResource(opts.path);

      if (existingResource) {
        return existingResource;
      }

      const newResource = new SubbableResource(opts);
      this.resources.push(newResource);

      return newResource;
    }

    existingResource(optsPath) {
      this.resources.find((resource) => {
        return resource.path === optsPath;
      });
    }
  }

  const resourceFactory = new SubbableResourceFactory();

  // only expose creation method
  global.createSubbableResource = resourceFactory.create.bind(resourceFactory);

})(window.gl || (window.gl = {}));
