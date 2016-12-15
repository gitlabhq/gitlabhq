//= require ./approvals/stores/approvals_store

(() => {
  let singleton;

  class MergeRequestWidgetStore {
    constructor(rootEl) {
      if (!singleton) {
        singleton = gl.MergeRequestWidget.Store = this;
        this.init(rootEl);
      }
      return singleton;
    }

    init(rootEl) {
      this.rootEl = rootEl;
      this.dataset = rootEl.dataset;
      this.data = {};

      // init other widget stores here
      this.initApprovals();
    }

    initApprovals() {
      gl.ApprovalsStore = new gl.ApprovalsStore(this);
      this.assignToData('approvals', {});
    }

    assignToData(key, val) {
      this.data[key] = val;
      return this.data[key];
    }
  }
  gl.MergeRequestWidgetStore = MergeRequestWidgetStore;
})(window.gl || (window.gl = {}));
