//= require ./approvals/stores/approvals_store

((MergeRequestWidget) => {
  let singleton;
  class MergeRequestWidgetStore {
    constructor(rootEl) {
      if (!singleton) {
        singleton = MergeRequestWidget.Store = this;
        this.init(rootEl);
      }
      return singleton;
      // TODO: add the following to the root el dataset: approvedByUsers,
      // approverNames, approvalsNeeded, canUpdateMergeRequest, endpoint
    }

    init(rootEl) {
      this.rootEl = rootEl;
      this.dataset = rootEl.dataset;
      this.data = {};
      this.initResource();
      this.initPermissions();
      this.initApprovals();
    }

    /* General Resources */

    initResource() {
      this.assignToData('resource', {
        endpoint: 'my/endpoint',
      });
    }

    initPermissions() {
      this.assignToData('permissions', {
        canUpdateMergeRequest: Boolean(this.dataset.canUpdateMergeRequest),
      });
    }

    /* Component-specific */

    initApprovals() {
      const approvalsStore = new gl.MergeRequestWidget.ApprovalsStore(this.rootEl);
      this.assignToData('approvals', approvalsStore.data);
    }

    assignToData(key, val) {
      this.data[key] = {};
      Object.assign(this.data[key], val);
    }
  }

  MergeRequestWidget.Store = MergeRequestWidgetStore;
})(gl.MergeRequestWidget || (MergeRequestWidget = {}));
