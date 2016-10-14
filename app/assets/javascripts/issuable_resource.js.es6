/*
*
*   IssuableResource is a pubsub-style service that polls the server for updates to
*   an Issuable model and propagates changes to subscribers throughout the page. It is designed
*   to update Vue-ized and non-Vue-ized components.
*
*   Subscribe by passing in the Issuable property you want to be notified of updates to, and pass
*   a callback or render method you will use to render your component's updated state.
*
*   Currently this service only handles fetching new data. Eventually it would make sense to
*   route more, if not all, Issuable ajax traffic through this class, to prevent conflicts and/or
*   unneccessary requests.
*
*   JQuery usage:
*
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

//= require vue
//= require vue-resource

((global) => {

  let singleton;

  class IssuableResource {
    constructor(path, issuable) {
      if (!singleton) {
        singleton = global.IssuableResource  = this;
        singleton.init(path, issuable);
      }
      return singleton;
    }

    init(path, issuable) {
      this.state = JSON.parse(issuable);
      this.resource = Vue.resource(path);
      this.subscribers = {};
      this.initPolling();
    }

    initPolling() {
      setInterval(() => {
        this.getIssuable();
      }, 1000);
    }

    getIssuable() {
      return this.resource.get()
        .then((res) => this.updateState(res.data))
        .then((newState) => this.publish(newState));
    }

    putIssuable() {

    }

    deleteIssuable() {

    }

    addSubscriber(prop, callback) {
      const isNewProp = !this.subscribers.hasOwnProperty(prop);
      if (isNewProp) {
        this.subscribers[prop] = [];
      }
      this.subscribers[prop].push(callback);
    }

    publish(diff) {
      // prevent subscribers mutating state
      const stateCopy = _.extend({}, this.state);
      for (var key in diff) {
        const hasSubscribers = this.subscribers.hasOwnProperty(key);
        if (hasSubscribers) {
          this.subscribers[key].forEach((fn) => {
            fn(stateCopy);
          });
        }
      }
    }

    subscribe(propToWatch, callback) {
      this.addSubscriber(propToWatch, callback);
    }

    updateState(res) {
      const diff = {};
      if (res.updated_at !== this.state.updated_at) {
        for (var key in res) {
          const val = res[key];
          if (this.state[key] !== val) {
            diff[key] = val;
          }
        }
        this.state = _.extend(this.state, diff);
      }
      return diff;
    }
  }

  global.IssuableResource = IssuableResource;

})(window.gl || (window.gl = {}));
