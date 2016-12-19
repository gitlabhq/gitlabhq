/* global Vue */
//= require ../approvals_store
//= require ../approvals_api

(() => {
  Vue.component('approvals-body', {
    name: 'approvals-body',
    props: {
      approvedBy: {
        type: Array,
        required: false,
      },
      approvalsLeft: {
        type: Number,
        required: false,
      },
      userCanApprove: {
        type: Boolean,
        required: false,
      },
      userHasApproved: {
        type: Boolean,
        required: false,
      } ,
      suggestedApprovers: {
        type: Array,
        required: false,
      }
    },
    computed: {
      approvalsRequiredStringified() {
        const baseString = `${this.approvalsLeft} more approval`;
        return this.approvalsLeft === 1 ? baseString : `${baseString}s`;
      },
      approverNamesStringified() {
        const approvers = this.suggestedApprovers;

        if (!approvers) {
          return '';
        }

        return approvers.length === 1 ? approvers[0].name :
          approvers.reduce((memo, curr, index) => {
            const nextMemo = `${memo}${curr.name}`;

            if (index === approvers.length - 2) { // second to last index
              return `${nextMemo} or `;
            } else if (index === approvers.length - 1) { // last index
              return nextMemo;
            }

            return `${nextMemo}, `;
          }, '');
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
      gl.ApprovalsStore.initStoreOnce();
    },
    template: `
      <div class='approvals-body mr-widget-body'>
        <h4> Requires {{ approvalsRequiredStringified }}
          <span> (from {{ approverNamesStringified }}) </span>
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
