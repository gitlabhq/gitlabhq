//= require ../services/approvals_api

(() => {
  let singleton;

  class ApprovalsStore {
    constructor(rootStore) {
      if (!singleton) {
        singleton = gl.ApprovalsStore = this;
        this.init(rootStore);
      }
      return singleton;
    }

    init(rootStore) {
      this.rootStore = rootStore;
      this.api = new gl.ApprovalsApi(rootStore.dataset.endpoint);
      this.state = {
        loading: false,
      };
    }

    initStoreOnce() {
      const state = this.state;
      if (!state.loading) {
        state.loading = true;
        return this.fetch()
          .then(() => {
            state.loading = false;
            this.assignToRootStore(false, 'loading');
          })
          .catch((err) => {
            console.error(`Failed to initialize approvals store: ${err}`);
          });
      }
      return Promise.resolve();
    }

    fetch() {
      return this.api.fetchApprovals()
        .then(res => this.assignToRootStore('approvals', res.data));
    }

    approve() {
      return this.api.approveMergeRequest()
        .then(res => this.assignToRootStore('approvals', res.data))
        .then(data => this.maybeHideWidgetBody(data.approvals_left));
    }

    unapprove() {
      return this.api.unapproveMergeRequest()
        .then(res => this.assignToRootStore('approvals', res.data))
        .then(data => this.maybeHideWidgetBody(data.approvals_left));
    }

    assignToRootStore(key, data) {
      return this.rootStore.assignToData(key, data);
    }
  }
  gl.ApprovalsStore = ApprovalsStore;
})();

