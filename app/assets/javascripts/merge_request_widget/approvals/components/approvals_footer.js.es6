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
    props: ['approverNames', 'canApprove', 'approvedByUsers'],
    methods: {
      removeApproval() {
        this.$emit('remove-approval');
      }
    },
    components: {
      'pending-approver': PendingApprover,
    },
    methods: {

    },
    template: `
      <div>
        Hello Approvals Footer
        <div>
          <div v-for='approver in approvedByUsers'>
            <link-to-member-avatar 
              :avatar-url='approver.avatar.url'
              :display-name='approver.name'
              :username='approver.username'>
            </link-to-member-avatar>
          </div>
          <span v-if='canApprove'>
            <i class='fa fa-close'></i>
            <button @click='removeApproval'>Remove your approval</button>
            {{ approvedByUsers[0].name }}
          </span>
        </div>
      </div>
    `
  };

})();
