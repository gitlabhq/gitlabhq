/* global Vue */
//= require ../approvals_store
//= require vue_common_component/link_to_member_avatar

(() => {
  Vue.component('approvals-footer', {
    name: 'approvals-footer',
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
      pendingAvatarSvg: {
        type: String,
        required: true,
      },
      checkmarkSvg: {
        type: String,
        required: true,
      },
    },
    computed: {
      hasApprovers() {
        return this.approvedBy && this.approvedBy.length;
      },
      showUnapproveButton() {
        return this.userHasApproved && !this.userCanApprove;
      },
    },
    methods: {
      removeApproval() {
        gl.ApprovalsStore.unapprove();
      },
    },
    beforeCreate() {
      gl.ApprovalsStore.initStoreOnce();
    },
    template: `
      <div class='mr-widget-footer approved-by-users approvals-footer clearfix'>
        <span class='approvers-prefix'> Approved by </span>
        <span v-for='approver in approvedBy'>
          <link-to-member-avatar
            extra-link-class='approver-avatar'
            :avatar-url='approver.user.avatar_url'
            :display-name='approver.user.name'
            :profile-url='approver.user.web_url'
            :avatar-html='checkmarkSvg'
            :show-tooltip='true'>
          </link-to-member-avatar>
        </span>
        <span v-for='n in approvalsLeft'>
          <link-to-member-avatar
            :clickable='false'
            :avatar-html='pendingAvatarSvg'
            :show-tooltip='false'
            extra-link-class='hide-asset'>
          </link-to-member-avatar>
        </span>
        <span class='unapprove-btn-wrap' v-if='showUnapproveButton'>
          <i class='fa fa-close'></i>
          <span class='unapprove-btn' @click='removeApproval()'>Remove your approval</span>
        </span>
      </div>
    `,
  });
})();

