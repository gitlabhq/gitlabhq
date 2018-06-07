<script>
import Flash from '~/flash';
import statusIcon from '~/vue_merge_request_widget/components/mr_widget_status_icon.vue';
import { s__ } from '~/locale';
import ApprovalsBody from './approvals_body.vue';
import ApprovalsFooter from './approvals_footer.vue';

export default {
  name: 'MRWidgetApprovals',
  components: {
    ApprovalsBody,
    ApprovalsFooter,
    statusIcon,
  },
  props: {
    mr: {
      type: Object,
      required: true,
    },
    service: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      fetchingApprovals: true,
    };
  },

  computed: {
    status() {
      if (this.mr.approvals.approvals_left > 0) {
        return 'warning';
      }
      return 'success';
    },
    approvalsOptional() {
      return (
        !this.fetchingApprovals &&
        this.mr.approvals.approvals_required === 0 &&
        this.mr.approvals.approved_by.length === 0
      );
    },
  },
  created() {
    const flashErrorMessage = s__(
      'mrWidget|An error occured while retrieving approval data for this merge request.',
    );

    this.service
      .fetchApprovals()
      .then(data => {
        this.mr.setApprovals(data);
        this.fetchingApprovals = false;
      })
      .catch(() => new Flash(flashErrorMessage));
  },
};
</script>
<template>
  <div
    v-if="mr.approvalsRequired"
    class="mr-widget-approvals-container mr-widget-section media"
  >
    <status-icon
      :class="approvalsOptional ? 'zero-approvals' : ''"
      :status="fetchingApprovals ? 'loading' : status"
    />
    <div
      v-show="fetchingApprovals"
      class="mr-approvals-loading-state media-body"
    >
      <span class="approvals-loading-text">
        Checking approval status
      </span>
    </div>
    <div
      v-if="!fetchingApprovals"
      class="approvals-components media-body"
    >
      <approvals-body
        :mr="mr"
        :service="service"
        :user-can-approve="mr.approvals.user_can_approve"
        :user-has-approved="mr.approvals.user_has_approved"
        :approved-by="mr.approvals.approved_by"
        :approvals-left="mr.approvals.approvals_left"
        :approvals-optional="approvalsOptional"
        :suggested-approvers="mr.approvals.suggested_approvers"
      />
      <approvals-footer
        :mr="mr"
        :service="service"
        :user-can-approve="mr.approvals.user_can_approve"
        :user-has-approved="mr.approvals.user_has_approved"
        :approved-by="mr.approvals.approved_by"
        :approvals-left="mr.approvals.approvals_left"
      />
    </div>
  </div>
</template>
