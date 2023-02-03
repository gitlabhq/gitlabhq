<script>
import { GlSkeletonLoader } from '@gitlab/ui';
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
import approvedByQuery from 'ee_else_ce/vue_merge_request_widget/components/approvals/queries/approved_by.query.graphql';

export default {
  apollo: {
    approvalState: {
      query: approvedByQuery,
      variables() {
        return {
          projectPath: this.projectPath,
          iid: this.iid,
        };
      },
      update: (data) => data.project.mergeRequest,
    },
  },
  components: {
    GlSkeletonLoader,
    UserAvatarList,
  },
  props: {
    projectPath: {
      type: String,
      required: true,
    },
    iid: {
      type: String,
      required: true,
    },
    updatedCount: {
      type: Number,
      required: false,
      default: 0,
    },
    multipleApprovalRulesAvailable: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      approvalState: {},
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
        (this.approvalState.approvalState?.rules || []).filter((r) => r.approvalsRequired !== 0),
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
    currentUserId() {
      return gon.current_user_id;
    },
  },
  watch: {
    updatedCount() {
      this.$apollo.queries.approvalState.refetch();
    },
  },
};
</script>

<template>
  <div data-qa-selector="approvals_summary_content">
    <div
      v-if="$apollo.queries.approvalState.loading"
      class="gl-display-inline-block gl-vertical-align-middle"
      style="width: 132px; height: 24px"
    >
      <gl-skeleton-loader :width="132" :height="24">
        <rect width="100" height="24" x="0" y="0" rx="4" />
        <circle cx="120" cy="12" r="12" />
      </gl-skeleton-loader>
    </div>
    <template v-else>
      <span class="gl-font-weight-bold">{{ approvalLeftMessage }}</span>
      <template v-if="hasApprovers">
        <span v-if="approvalLeftMessage">{{ message }}</span>
        <span v-else class="gl-font-weight-bold">{{ message }}</span>
        <user-avatar-list
          class="gl-display-inline-block gl-vertical-align-middle gl-pt-1"
          :img-size="24"
          :items="approvers"
        />
      </template>
    </template>
  </div>
</template>
