//= require ../services/approvals_api

(() => {
  const app = gl.MergeRequestWidget;
  const api = gl.MergeRequestWidget.ApprovalsApi;
  const componentRegistry = app.Components || (app.Components = {});

  componentRegistry.approvalsBody = {
    name: 'ApprovalsBody',
    props: ['approverNames', 'approvalsLeft', 'canApprove'],
    data() {
      return {
        loading: true,
      };
    },
    computed: {
      approvalsRequiredStringified() {
        return this.approvalsLeft === 1 ? 'one more approval' :
          `${this.approvalsLeft} more approvals`;
      },
      approverNamesStringified() {
        const lastIdx = this.approverNames.length - 1;
        return this.approverNames.reduce((memo, curr, index) => {
          const newList = index !== lastIdx ? `${memo} ${curr}, ` :
            `${memo} or ${curr}`;
          return newList;
        }, '');
      },
    },
    methods: {
      approveMergeRequest() {
        return api.approveMergeRequest();
      },
    },
    beforeCreate() {
      api.fetchApprovals().then(() => {
        this.loading = false;
      });
    },
    template: `
      <div>
        <div>
          <h4> Requires {{ approvalsRequiredStringified }} (from {{ approverNamesStringified }})</h4>
          <div class='append-bottom-10'>
            <button 
              v-if='canApprove' 
              @click='approveMergeRequest' 
              class='btn btn-primary approve-btn'> 
              Approve Merge Request
            </button>
          </div>
        </div>
        <loading-icon v-if='loading'></loading-icon>
      </div>
    `,
  };
})();
