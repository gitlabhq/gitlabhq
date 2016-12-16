//= require ../stores/approvals_store
//= require ../services/approvals_api

(() => {
  Vue.component('approvals-body', {
    name: 'approvals-body',
    props: ['approvedBy', 'approvalsLeft', 'userCanApprove', 'userHasApproved', 'suggestedApprovers', 'widgetLoading'],
    computed: {
      approvalsRequiredStringified() {
        return this.approvalsLeft === 1 ? 'one more approval' :
          `${this.approvalsLeft} more approvals`;
      },
      approverNamesStringified() {
        const approvers = this.suggestedApprovers;
        if (approvers && approvers.length) {
          if (approvers.length === 1) {
            return approvers[0].name;
          }
          const lastIndex = approvers.length - 1;
          const nextToLastIndex = approvers.length - 2;
          return approvers.reduce((memo, curr, index) => {
            let suffix;

            if (index === nextToLastIndex) {
              suffix = ' or ';
            } else if (index === lastIndex) {
              suffix = '';
            } else {
              suffix = ', ';
            }

            const nameToAdd = `${curr.name}${suffix}`;
            return `${memo}${nameToAdd}`;
          }, '');
        }
        return null;
      },
      showApproveButton() {
        return this.userCanApprove && !this.userHasApproved;
      },
      showApprovalsBody() {
        return !this.widgetLoading && this.approvalsLeft;
      }
    },
    methods: {
      approveMergeRequest() {
        return gl.ApprovalsStore.approve();
      },
    },
    beforeCreate() {
      gl.ApprovalsStore.initStoreOnce();
    },
    template: `
      <div class='approvals-body' v-if='showApprovalsBody'>
        <h4> Requires {{ approvalsRequiredStringified }} (from {{ approverNamesStringified }})</h4>
        <div v-if='showApproveButton' class='append-bottom-10'>
          <button
            @click='approveMergeRequest'
            class='btn btn-primary approve-btn'>
            Approve Merge Request
          </button>
        </div>
      </div>
    `,
  });
})();
