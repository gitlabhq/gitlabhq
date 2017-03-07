require('./approvals_api');

let singleton;

class MergeRequestApprovalsStore {
  constructor(rootStore) {
    if (!singleton) {
      singleton = this;
      this.init(rootStore);
    }
    return singleton;
  }

  init(rootStore) {
    this.rootStore = rootStore;
    this.api = new gl.ApprovalsApi(rootStore.rootEl.dataset.endpoint);
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
        });
    }
    return Promise.resolve();
  }

  fetch() {
    return this.api.fetchApprovals()
      .then(res => this.assignToRootStore('approvals', res.json()))
      .then(data => this.setMergeRequestAcceptanceStatus(data.approvals_left));
  }

  approve() {
    return this.api.approveMergeRequest()
      .then(res => this.assignToRootStore('approvals', res.json()))
      .then(data => this.setMergeRequestAcceptanceStatus(data.approvals_left));
  }

  unapprove() {
    return this.api.unapproveMergeRequest()
      .then(res => this.assignToRootStore('approvals', res.json()))
      .then(data => this.setMergeRequestAcceptanceStatus(data.approvals_left));
  }

  setMergeRequestAcceptanceStatus(approvalsLeft) {
    return this.rootStore.assignToData('disableAcceptance', !!approvalsLeft);
  }

  assignToRootStore(key, data) {
    return this.rootStore.assignToData(key, data);
  }
}

window.gl = window.gl || {};
window.gl.MergeRequestApprovalsStore = MergeRequestApprovalsStore;
