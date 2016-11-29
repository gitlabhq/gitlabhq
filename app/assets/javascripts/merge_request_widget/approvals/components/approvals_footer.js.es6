//= require vue_common_component/link_to_member_avatar

(() => {
  // does the user have permission to edit this thing
  // has the user already approved this or not
  // what are the users who have approved this already, with all their info
  gl.MergeRequestWidget.approvalsFooter = {
    props: ['canUpdateMergeRequest', 'hasApprovedMergeRequest', 'approvedByUsers'],
    methods: {
      removeApproval() {
        approvalsService.unapproveMergeRequest();
      }
    },
    beforeCreate() {
      approvalsService.fetchApprovals();
    },
    template: `
      <div>
        <div v-for='approver in approvedByUsers'>
          <link-to-member-avatar 
            :avatar-url='approver.avatar.url'
            :display-name='approver.name'
            :username='approver.username'>
          </link-to-member-avatar>
        </div>
        <span>
          <i class='fa fa-close'></i>
          <button @click='removeApproval'>Remove your approval</button>
          {{ approvedByUsers[0].name }}
        </span>
      </div>
    `
  };
})();
