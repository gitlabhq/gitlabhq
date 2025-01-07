<script>
import { GlLink, GlPopover } from '@gitlab/ui';
import PolicyApprovalSettingsIcon from 'ee_component/vue_merge_request_widget/components/approvals/policy_approval_settings_icon.vue';
import { toNounSeriesText } from '~/lib/utils/grammar';
import { n__, sprintf } from '~/locale';
import {
  APPROVED_BY_YOU_AND_OTHERS,
  APPROVED_BY_YOU,
  APPROVED_BY_OTHERS,
} from '~/vue_merge_request_widget/components/approvals/messages';
import UserAvatarList from '~/vue_shared/components/user_avatar/user_avatar_list.vue';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { getApprovalRuleNamesLeft } from 'ee_else_ce/vue_merge_request_widget/mappers';

export default {
  components: {
    GlLink,
    GlPopover,
    UserAvatarList,
    PolicyApprovalSettingsIcon,
  },
  props: {
    multipleApprovalRulesAvailable: {
      type: Boolean,
      required: false,
      default: false,
    },
    approvalState: {
      type: Object,
      required: true,
    },
    disableCommittersApproval: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isUserAvatarListExpanded: false,
    };
  },
  computed: {
    approvers() {
      return this.approvalState.approvedBy?.nodes || [];
    },
    approved() {
      return this.approvalState.approved || this.approvalState.approvedBy?.nodes.length > 0;
    },
    approvalsLeft() {
      return this.approvalState.approvalsLeft || 0;
    },
    rulesLeft() {
      return getApprovalRuleNamesLeft(
        this.multipleApprovalRulesAvailable,
        (this.approvalState.approvalState?.rules || []).filter((r) => !r.approved),
      );
    },
    approvalLeftMessage() {
      if (this.rulesLeft.length) {
        return sprintf(
          n__(
            'Requires %{count} approval from %{names}.',
            'Requires %{count} approvals from %{names}.',
            this.approvalsLeft,
          ),
          {
            names: toNounSeriesText(this.rulesLeft),
            count: this.approvalsLeft,
          },
          false,
        );
      }

      if (!this.approved) {
        return n__(
          'Requires %d approval from eligible users.',
          'Requires %d approvals from eligible users.',
          this.approvalsLeft,
        );
      }

      return '';
    },
    message() {
      if (this.approvedByMe && this.approvedByOthers) {
        return APPROVED_BY_YOU_AND_OTHERS;
      }

      if (this.approvedByMe) {
        return APPROVED_BY_YOU;
      }

      if (this.approved) {
        return APPROVED_BY_OTHERS;
      }

      return '';
    },
    hasApprovers() {
      return Boolean(this.approvers.length);
    },
    approvedByMe() {
      if (!this.currentUserId) {
        return false;
      }
      return this.approvers.some(
        (approver) => getIdFromGraphQLId(approver.id) === this.currentUserId,
      );
    },
    approvedByOthers() {
      if (!this.currentUserId) {
        return false;
      }
      return this.approvers.some(
        (approver) => getIdFromGraphQLId(approver.id) !== this.currentUserId,
      );
    },
    currentUserHasCommitted() {
      if (!this.currentUserId) return false;

      return this.approvalState.committers?.nodes?.some(
        (user) => getIdFromGraphQLId(user.id) === this.currentUserId,
      );
    },
    currentUserId() {
      return gon.current_user_id;
    },
    policiesOverridingApprovalSettings() {
      return this.approvalState.policiesOverridingApprovalSettings;
    },
  },
  methods: {
    onUserAvatarListExpanded() {
      this.isUserAvatarListExpanded = true;
    },
    onUserAvatarListCollapsed() {
      this.isUserAvatarListExpanded = false;
    },
  },
};
</script>

<template>
  <div
    class="gl-flex gl-flex-wrap gl-items-center gl-gap-2"
    data-testid="approvals-summary-content"
  >
    <span v-if="approvalLeftMessage" class="gl-font-bold">{{ approvalLeftMessage }}</span>
    <template v-if="hasApprovers">
      <span v-if="approvalLeftMessage">{{ message }}</span>
      <span v-else class="gl-font-bold">{{ message }}</span>
      <user-avatar-list
        class="gl-inline-block"
        :class="{ 'gl-pt-1': isUserAvatarListExpanded }"
        :img-size="24"
        :items="approvers"
        @expanded="onUserAvatarListExpanded"
        @collapsed="onUserAvatarListCollapsed"
      />
    </template>
    <policy-approval-settings-icon :policies="policiesOverridingApprovalSettings" />
    <template v-if="disableCommittersApproval && currentUserHasCommitted">
      <gl-link id="cant-approve-popover" data-testid="commit-cant-approve" class="gl-cursor-help">{{
        __("Why can't I approve?")
      }}</gl-link>
      <gl-popover target="cant-approve-popover">
        {{ __("You can't approve because you added one or more commits to this merge request.") }}
      </gl-popover>
    </template>
  </div>
</template>
