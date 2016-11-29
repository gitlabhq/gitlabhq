(() => {
  // can the user edit this MR
  // has this user approved this MR
  // What is the info about users who can approve this MR but have not yet?
  // How many approvals are needed?
  // How many approvals are had?
  gl.MergeRequestWidget.approvalsBody = {
    props: ['approverNames', 'approvalsLeft', 'canApprove'],
    computed: {
      approvalsRequiredStringified() {
        return this.approvalsLeft === 1 ? "one more approval" :
          `${this.approvalsLeft} more approvals`;
      },
      approverNamesStringified() {
        const lastIdx = this.approverNames.length - 1;
        return this.approverNames.reduce((memo, curr, index) => {
          return index !== lastIdx ? `${memo} ${curr}, ` : `${memo} or ${curr}`;
        }, '');
      }
    }, 
    methods: {
      approveMergeRequest() {
        approvalsService.approveMergeRequest();
      },
    },
    beforeCreate() {
      approvalsService.fetchApprovals();
    },
    template: `
      <div>
        <h4> Requires {{ approvalsRequiredStringified }} (from {{ approverNamesStringified }})</h4>
        <div class="append-bottom-10">
          <button v-if='canApprove' @click='approveMergeRequest' class="btn btn-primary approve-btn">Approve Merge Request</button>
        </div>
      </div>
    `,
   
  };
})();
