/* global Vue */
//= require ./approvals_api

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
        fetching: false,
      };
    }

    initStoreOnce() {
      const state = this.state;
      if (!state.fetching) {
        state.fetching = true;
        return this.fetch()
          .then(() => {
            state.fetching = false;
            this.assignToRootStore('showApprovals', true);
          })
          .catch((err) => {
            console.error(`Failed to initialize approvals store: ${err}`);
          });
      }
      return Promise.resolve();
    }

    fetch() {
      return this.api.fetchApprovals()
        .then(res => this.assignToRootStore('approvals', res.data))
        .then(data => this.setMergeRequestAcceptanceStatus(data.approvalsLeft));
    }

    approve() {
      return this.api.approveMergeRequest()
        .then(res => this.assignToRootStore('approvals', res.data))
        .then(data => this.setMergeRequestAcceptanceStatus(data.approvalsLeft));
    }

    unapprove() {
      return this.api.unapproveMergeRequest()
        .then(res => this.assignToRootStore('approvals', res.data))
        .then(data => this.setMergeRequestAcceptanceStatus(data.approvalsLeft));
    }

    setMergeRequestAcceptanceStatus(approvalsLeft) {
      return this.rootStore.assignToData('disableAcceptance', !!approvalsLeft);
    }

    assignToRootStore(key, data) {
      return this.rootStore.assignToData(key, data);
    }
  }
  gl.ApprovalsStore = ApprovalsStore;
})();

