//= require ../services/approvals_api
//= require vue_common_component/link_to_member_avatar
//= require vue_common_component/loading_icon

(() => {
  const app = gl.MergeRequestWidget;
  const api = gl.MergeRequestWidget.ApprovalsApi;
  const componentRegistry = app.Components || (app.Components = {});

  componentRegistry.approvalsFooter = {
    name: 'ApprovalsFooter',
    props: ['canUpdateMergeRequest', 'hasApprovedMergeRequest', 'approvedByUsers'],
    data() {
      return {
        loading: true,
      };
    },
    methods: {
      removeApproval() {
        return api.unapproveMergeRequest();
      },
    },
    beforeCreate() {
      api.fetchApprovals().then(() => {
        this.loading = false;
      });
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
        </span>
        <loading-icon v-if='loading'></loading-icon>
      </div>
    `,
  };
})();
