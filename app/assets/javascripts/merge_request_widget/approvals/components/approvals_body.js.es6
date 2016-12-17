(() => {
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
        this.$emit('user-gives-approval');
      },
    },
    template: `
      <div> Hello approval body 
        <h4> Requires {{ approvalsRequiredStringified }} (from {{ approverNamesStringified }})</h4>
        <div class="append-bottom-10">
          <button v-if='canApprove' @click='approveMergeRequest' class="btn btn-primary approve-btn">Approve Merge Request</button>
        </div>
      </div>
    `,
   
  };
})();