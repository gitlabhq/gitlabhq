//= require ../stores/approvals_store
//= require ../services/approvals_api

(() => {
  Vue.component('approvals-body', {
    name: 'approvals-body',
    props: ['approvedBy', 'approvalsLeft', 'userCanApprove', 'userHasApproved'],
    computed: {
      approvalsRequiredStringified() {
        return this.approvalsLeft === 1 ? 'one more approval' :
          `${this.approvalsLeft} more approvals`;
      },
      approverNamesStringified() {
        const approvers = this.approvedBy;
        if (approvers && approvers.length) {
          const lastIdx = approvers.length - 1;
          return approvers.reduce((memo, curr, index) => {
            const userDisplayName = curr.user.name;
            const newList = index !== lastIdx ? `${memo} ${userDisplayName}, ` :
              `${memo} or ${userDisplayName}`;
            return newList;
          }, '');
        }
      },
      showApproveButton() {
        return this.userCanApprove && !this.userHasApproved;
      },
    },
    methods: {
      approveMergeRequest() {
        return gl.ApprovalsStore.approve();
      },
    },
    beforeCreate() {
      return gl.ApprovalsStore.fetch().then();
    },
    template: `
      <div>
        <div>
          <h4> Requires {{ approvalsRequiredStringified }} (from {{ approverNamesStringified }})</h4>
          <div v-if='showApproveButton' class='append-bottom-10'>
            <button
              @click='approveMergeRequest'
              class='btn btn-primary approve-btn'>
              Approve Merge Request
            </button>
          </div>
        </div>
      </div>
    `,
  });
})();
