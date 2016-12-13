//= require ../stores/approvals_store
//= require vue_common_component/link_to_member_avatar
//= require vue_common_component/loading_icon

(() => {

  Vue.component('approvals-footer', {
    name: 'approvals-footer',
    props: ['userCanApprove', 'userHasApproved', 'approvedBy', 'approvalsLeft', 'pendingAvatarSvg', 'checkmarkSvg'],
    data() {
      return {
        loading: true,
      };
    },
    computed: {
      hasApprovers() {
        return this.approvedBy && this.approvedBy.length;
      },
      showUnapproveButton() {
        return this.userHasApproved;
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
        <span v-for='approver in approvedBy'>
          <link-to-member-avatar
            extra-link-class='approver-avatar'
            :avatar-url='approver.user.avatar_url'
            :display-name='approver.user.name'
            :username='approver.user.username'
            :profile-url='approver.user.web_url'
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

/*
 *{':user-can-approve' => 'approvals.user_can_approve', ':user-has-approved' => 'approvals.user-has-approved', ':approved-by' => 'approvals.approved_by', ':approvals-left':'approvals.approvals_left'}2
approvals_required
:
3
approved_by
:
Array[1]
0
:
Object
length
:
1
__proto__
:
Array[0]
created_at
:
"2016-10-17T17:26:13.169Z"
description
:
"Quod corporis labore maiores voluptates ad nobis rem earum. Fugit aperiam officiis temporibus nemo qui consequatur. Perspiciatis maiores expedita est omnis vitae et assumenda."
id
:
7
iid
:
7
merge_status
:
"can_be_merged"
project_id
:
8
state
:
"reopened"
title
:
"Autem ea aut rem rerum sed et eligendi vel doloribus perferendis."
updated_at
:
"2016-12-08T17:20:40.530Z"
user_can_approve
:
false
user_has_approved
:
true
 *
 *
 * */
