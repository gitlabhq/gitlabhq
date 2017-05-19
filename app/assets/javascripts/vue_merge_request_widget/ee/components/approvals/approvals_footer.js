/* global Flash */
import pendingAvatarSvg from 'icons/_icon_dotted_circle.svg';
import LinkToMemberAvatar from '~/vue_shared/components/link_to_member_avatar';
import eventHub from '../../../event_hub';

export default {
  name: 'approvals-footer',
  props: {
    mr: {
      type: Object,
      required: true,
    },
    service: {
      type: Object,
      required: true,
    },
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
  },
  data() {
    return {
      unapproving: false,
      pendingAvatarSvg,
    };
  },
  components: {
    'link-to-member-avatar': LinkToMemberAvatar,
  },
  computed: {
    showUnapproveButton() {
      const isMerged = this.mr.state === 'merged';
      return this.userHasApproved && !this.userCanApprove && !isMerged;
    },
  },
  methods: {
    unapproveMergeRequest() {
      this.unapproving = true;
      this.service.unapproveMergeRequest()
        .then((data) => {
          this.mr.setApprovals(data);
          eventHub.$emit('MRWidgetUpdateRequested');
          this.unapproving = false;
        })
        .catch(() => {
          this.unapproving = false;
          new Flash('An error occured while removing your approval.'); // eslint-disable-line
        });
    },
  },
  template: `
    <div v-if="approvedBy.length" class="approved-by-users approvals-footer clearfix mr-info-list">
      <div class="legend"></div>
      <div>
        <p class="approvers-prefix">Approved by</p>
        <div class="approvers-list">
          <span v-for="approver in approvedBy">
            <link-to-member-avatar
              extra-link-class="approver-avatar"
              :avatar-url="approver.user.avatar_url"
              :display-name="approver.user.name"
              :profile-url="approver.user.web_url"
              :show-tooltip="true" />
          </span>
          <span class="potential-approvers-list" v-for="n in approvalsLeft">
            <link-to-member-avatar
              :clickable="false"
              :avatar-html="pendingAvatarSvg"
              :show-tooltip="false"
              extra-link-class="hide-asset" />
          </span>
        </div>
        <span class="unapprove-btn-wrap" v-if="showUnapproveButton">
          <button
            :disabled="unapproving"
            @click="unapproveMergeRequest"
            class="btn btn-sm">
            <i
              v-if="unapproving"
              class="fa fa-spinner fa-spin"
              aria-hidden="true" />
            Remove your approval
          </button>
        </span>
      </div>
    </div>
  `,
};
