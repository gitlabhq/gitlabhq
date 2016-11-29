(() => {
  class MergeRequestWidgetStore {
    constructor(el) {
      this.dataset = el.dataset;
      this.data = {};
      
      // TODO: Break each into their own store
      this.initResource();
      this.initPermissions();
      this.initApprovals();
    }
    
    initResource() {
      Object.assign(this.data, {
        resource: { 
          canEdit: this.dataset.endpoint
        }
      });
    }

    initPermissions() {
      Object.assign(this.data, {
        permissions: { 
          canEdit: Boolean(this.dataset.canEdit)
        }
      });
    }

    initApprovals() {
      const dataset = this.dataset;
      Object.assign( this.data, { 
        approvals: {
          approvedByUsers: JSON.parse(dataset.approvedByUsers),
          approverNames: JSON.parse(dataset.approverNames),
          approvalsLeft: Number(dataset.approvalsLeft),
          moreApprovals: Number(dataset.approvalsLeft),
        }
      });
    }
  }
  gl.MergeRequestWidgetStore = MergeRequestWidgetStore; 
})()

