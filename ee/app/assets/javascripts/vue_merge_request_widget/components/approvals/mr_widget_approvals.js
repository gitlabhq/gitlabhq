import Flash from '~/flash';
import statusIcon from '~/vue_merge_request_widget/components/mr_widget_status_icon';
import ApprovalsBody from './approvals_body';
import ApprovalsFooter from './approvals_footer';

export default {
  name: 'MRWidgetApprovals',
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
  components: {
    'approvals-body': ApprovalsBody,
    'approvals-footer': ApprovalsFooter,
    statusIcon,
  },
  computed: {
    status() {
      if (this.mr.approvals.approvals_left > 0) {
        return 'warning';
      }
      return 'success';
    },
  },
  created() {
    const flashErrorMessage = 'An error occured while retrieving approval data for this merge request.';

    this.service.fetchApprovals()
      .then((data) => {
        this.mr.setApprovals(data);
        this.fetchingApprovals = false;
      })
      .catch(() => new Flash(flashErrorMessage));
  },
  template: `
    <div
      v-if="mr.approvalsRequired"
      class="mr-widget-approvals-container mr-widget-body mr-widget-section media">
      <div
        v-if="fetchingApprovals"
        class="mr-widget-icon">
        <i class="fa fa-spinner fa-spin" />
      </div>
      <status-icon v-else :status="status" />
      <div
        v-show="fetchingApprovals"
        class="mr-approvals-loading-state media-body">
        <span class="approvals-loading-text">
          Checking approval status
        </span>
      </div>
      <div
        v-if="!fetchingApprovals"
        class="approvals-components media-body">
        <approvals-body
          :mr="mr"
          :service="service"
          :user-can-approve="mr.approvals.user_can_approve"
          :user-has-approved="mr.approvals.user_has_approved"
          :approved-by="mr.approvals.approved_by"
          :approvals-left="mr.approvals.approvals_left"
          :suggested-approvers="mr.approvals.suggested_approvers" />
        <approvals-footer
          :mr="mr"
          :service="service"
          :user-can-approve="mr.approvals.user_can_approve"
          :user-has-approved="mr.approvals.user_has_approved"
          :approved-by="mr.approvals.approved_by"
          :approvals-left="mr.approvals.approvals_left" />
      </div>
    </div>
    `,
};
