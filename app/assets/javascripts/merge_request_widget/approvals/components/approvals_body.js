/* global Vue */

const Vue = require('vue');
require('../approvals_store');
require('../approvals_api');

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
    },
    suggestedApprovers: {
      type: Array,
      required: false,
    },
  },
  data() {
    return {
      approving: false,
    };
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
    showSuggestedApprovers() {
      return this.suggestedApprovers && this.suggestedApprovers.length;
    },
  },
  methods: {
    approveMergeRequest() {
      this.approving = true;
      return gl.ApprovalsStore.approve().then(() => {
        this.approving = false;
      });
    },
  },
  beforeCreate() {
    gl.ApprovalsStore.initStoreOnce();
  },
  template: `
    <div class='approvals-body mr-widget-footer mr-approvals-footer'>
      <h4> Requires {{ approvalsRequiredStringified }}
        <span v-if='showSuggestedApprovers'> (from {{ approverNamesStringified }}) </span>
      </h4>
      <div v-if='showApproveButton' class='append-bottom-10'>
        <button
          :disabled='approving'
          @click='approveMergeRequest'
          class='btn btn-primary approve-btn'>
          Approve Merge Request
        </button>
      </div>
    </div>
  `,
});
