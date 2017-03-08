/* global Vue */

const Vue = require('vue');
require('../approvals_store');
require('../../../vue_common_component/link_to_member_avatar');

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
  data() {
    return {
      unapproving: false,
    };
  },
  computed: {
    showUnapproveButton() {
      return this.userHasApproved && !this.userCanApprove;
    },
  },
  methods: {
    unapproveMergeRequest() {
      this.unapproving = true;
      gl.ApprovalsStore.unapprove().then(() => {
        this.unapproving = false;
      });
    },
  },
  beforeCreate() {
    gl.ApprovalsStore.initStoreOnce();
  },
  template: `
    <div class='mr-widget-footer approved-by-users approvals-footer clearfix mr-approvals-footer'>
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
        <button
          :disabled='unapproving'
          @click='unapproveMergeRequest'
          class='btn btn-link unapprove-btn'>
          <i class='fa fa-close'></i>
          Remove your approval</span>
        </button>
      </span>
    </div>
  `,
});
