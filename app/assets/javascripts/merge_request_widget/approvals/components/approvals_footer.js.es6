(() => {

  const PendingApprover = {
    data() {
      return {
        dottedCircleUrl: '/assets/no_avatar.png'
      };
    },
    template: `
      <span>
        <img width="24" alt="Required Approver" :src="dottedCircleUrl" class="avatar avatar-inline s24">
      </span>
    `
  };

  gl.MergeRequestWidget.approvalsFooter = {
    props: ['approverNames', 'canApprove'],
    methods: {
      removeApproval() {
        this.$emit('remove-approval');
      }
    },
    components: {
      'pending-approver': PendingApprover,
    },
    template: `
      <div>
        Hello Approvals Footer
        <div>
          <div v-for='approver in approverNames'>
            {{ approver }}
          </div>
          <span v-if='canApprove'>
            <i class='fa fa-close'></i>
            <button @click='removeApproval'>Remove your approval</button>
          </span>
        </div>
      </div>
    `
  };

})();
