//= require ../stores/approvals_store
//= require vue_common_component/link_to_member_avatar
//= require vue_common_component/loading_icon

(() => {

  Vue.component('approvals-footer', {
    name: 'approvals-footer',
    props: ['userCanApprove', 'userHasApproved', 'approvedByUsers', 'approvalsLeft', 'pendingAvatarSvg', 'checkmarkSvg'],
    data() {
      return {
        loading: true,
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
        return gl.ApprovalsStore.unapprove();
      },
    },
    beforeCreate() {
      return gl.ApprovalsStore.fetch().then(() => {
        this.loading = false;
      });
    },
    template: `
      <div v-if='hasApprovers' class='mr-widget-footer approved-by-users approvals-footer clearfix'>
        <span class='approvers-prefix'> Approved by </span>
        <span v-for='approver in approvedByUsers'>
          <link-to-member-avatar
            extra-link-class='approver-avatar'
            :avatar-url='approver.avatar.url'
            :display-name='approver.name'
            :username='approver.username'
            :avatar-html='checkmarkSvg'
            :show-tooltip='true'>
          </link-to-member-avatar>
        </span>
        <span v-for='n in approvalsLeft'>
          <link-to-member-avatar
            :non-user='true'
            :avatar-html='pendingAvatarSvg'
            :show-tooltip='false'
            extra-link-class='hide-asset'>
          </link-to-member-avatar>
        </span>
        <span class='unapprove-btn-wrap' v-if='showUnapproveButton'>
          <i class='fa fa-close'></i>
          <span @click='removeApproval'>Remove your approval</span>
        </span>
        <loading-icon v-if='loading'></loading-icon>
      </div>
    `,
  });
})();
