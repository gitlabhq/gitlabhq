// TODO: Bring in increasing interval util
// TODO: return a promise to subscribers?

/*
*   gl.IssuableResource.subscribe('assignee_id', (state) => {
*     console.log("Do something with the new state", state);
*   });
*
*
* */

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
