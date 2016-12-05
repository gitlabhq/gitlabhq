//= require ../services/approvals_api
//= require vue_common_component/link_to_member_avatar
//= require vue_common_component/loading_icon

(() => {
  const app = gl.MergeRequestWidget;
  const api = gl.MergeRequestWidget.ApprovalsApi;
  const componentRegistry = app.Components || (app.Components = {});

  componentRegistry.approvalsFooter = {
    name: 'ApprovalsFooter',
    props: ['userCanApprove', 'userHasApproved', 'approvedByUsers', 'approvalsLeft'],
    data() {
      return {
        loading: true,
        pendingAvatar: '/assets/no_avatar.png'
      };
    },
    computed: {
      hasApprovers() {
        return this.approvedByUsers && this.approvedByUsers.length;
      },
      showUnapproveButton() {
        return this.userCanApprove && this.userHasApproved;
      },
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
      <div v-if='hasApprovers' class='mr-widget-footer approved-by-users approvals-footer'>
        <span v-for='approver in approvedByUsers'>
          <link-to-member-avatar
            extra-link-class='approver-avatar'
            :avatar-url='approver.avatar.url'
            :display-name='approver.name'
            :username='approver.username'
            :show-tooltip='true'>
          </link-to-member-avatar>
        </span>
        <span v-for='n in approvalsLeft'>
          <link-to-member-avatar
            :non-user='true'
            :avatar-url='pendingAvatar'
            :show-tooltip='false'>
          </link-to-member-avatar>
        </span>
        <span  v-if='showUnapproveButton'>
          <i class='fa fa-close'></i>
          <button @click='removeApproval'>Remove your approval</button>
        </span>
        <loading-icon v-if='loading'></loading-icon>
      </div>
    `,
  };
})();
