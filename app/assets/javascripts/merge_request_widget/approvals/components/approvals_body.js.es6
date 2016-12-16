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
        if (approvers.length === 1) {
          return approvers[0].name;
        } else {
          return approvers.reduce((memo, curr, index) => {
            const nextMemo = `${memo}${curr.name}`;

            if (index === approvers.length - 2) { // second to last index
              return `${nextMemo} or `;
            } else if (index === approvers.length - 1) { // last index
              return nextMemo;
            }

            return `${nextMemo}, `;
          }, '');
        }
        return null;
      },
      showApproveButton() {
        return this.userCanApprove && !this.userHasApproved;
      },
      showApprovalsBody() {
        return !this.widgetLoading;
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
      <div class='approvals-body mr-widget-body' v-if='showApprovalsBody'>
        <h4> Requires {{ approvalsRequiredStringified }}
          <span v-if='!!suggestedApprovers.length'> (from {{ approverNamesStringified }}) </span>
        </h4>
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
