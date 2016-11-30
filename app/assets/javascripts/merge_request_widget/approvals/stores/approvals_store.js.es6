(() => {
  let singleton;

  class ApprovalsStore {
    constructor(rootEl) {
      if (!singleton) {
        singleton = gl.MergeRequestWidget.ApprovalsStore = this;
        this.init(rootEl);
      }
      return singleton;
    }

    init(rootEl) {
      this.data = {};
      const dataset = rootEl.dataset;

      this.assignToData({
        approvedByUsers: JSON.parse(dataset.approvedByUsers),
        approverNames: JSON.parse(dataset.approverNames),
        approvalsLeft: Number(dataset.approvalsLeft),
        moreApprovals: Number(dataset.moreApprovals),
      });
    }

    assignToData(val) {
      Object.assign(this.data, val);
    }
  }
  gl.MergeRequestWidget.ApprovalsStore = ApprovalsStore;
})();
