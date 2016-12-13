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
    }

    assignToRootStore(data) {
      return this.rootStore.assignToData('approvals', data);
    }

    fetch() {
      return this.api.fetchApprovals()
        .then(res => this.assignToRootStore(res.data));
    }

    approve() {
      return this.api.approveMergeRequest()
        .then(res => this.rootStore.assignToData(res.data));
    }

    unapprove() {
      return this.api.unapproveMergeRequest()
        .then(res => this.rootStore.assignToData(res.data));
    }
  }

  gl.ApprovalsStore = ApprovalsStore;
})();

