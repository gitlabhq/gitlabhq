<script>
import { GlButton } from '@gitlab/ui';
import createFlash from '~/flash';
import { BV_SHOW_MODAL } from '~/lib/utils/constants';
import { s__ } from '~/locale';
import eventHub from '../../event_hub';
import approvalsMixin from '../../mixins/approvals';
import MrWidgetContainer from '../mr_widget_container.vue';
import MrWidgetIcon from '../mr_widget_icon.vue';
import ApprovalsSummary from './approvals_summary.vue';
import ApprovalsSummaryOptional from './approvals_summary_optional.vue';
import { FETCH_LOADING, FETCH_ERROR, APPROVE_ERROR, UNAPPROVE_ERROR } from './messages';

export default {
  name: 'MRWidgetApprovals',
  components: {
    MrWidgetContainer,
    MrWidgetIcon,
    ApprovalsSummary,
    ApprovalsSummaryOptional,
    GlButton,
  },
  mixins: [approvalsMixin],
  props: {
    mr: {
      type: Object,
      required: true,
    },
    service: {
      type: Object,
      required: true,
    },
    isOptionalDefault: {
      type: Boolean,
      required: false,
      default: null,
    },
    approveDefault: {
      type: Function,
      required: false,
      default: null,
    },
    modalId: {
      type: String,
      required: false,
      default: null,
    },
    requirePasswordToApprove: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      fetchingApprovals: true,
      hasApprovalAuthError: false,
      isApproving: false,
    };
  },
  computed: {
    isBasic() {
      return this.mr.approvalsWidgetType === 'base';
    },
    isApproved() {
      return Boolean(this.approvals.approved);
    },
    isOptional() {
      return this.isOptionalDefault !== null ? this.isOptionalDefault : !this.approvedBy.length;
    },
    hasAction() {
      return Boolean(this.action);
    },
    approvals() {
      return this.mr.approvals || {};
    },
    approvedBy() {
      return this.approvals.approved_by ? this.approvals.approved_by.map((x) => x.user) : [];
    },
    userHasApproved() {
      return Boolean(this.approvals.user_has_approved);
    },
    userCanApprove() {
      return Boolean(this.approvals.user_can_approve);
    },
    showApprove() {
      return !this.userHasApproved && this.userCanApprove && this.mr.isOpen;
    },
    showUnapprove() {
      return this.userHasApproved && !this.userCanApprove && this.mr.state !== 'merged';
    },
    approvalText() {
      return this.isApproved && this.approvedBy.length > 0
        ? s__('mrWidget|Approve additionally')
        : s__('mrWidget|Approve');
    },
    action() {
      // Use the default approve action, only if we aren't using the auth component for it
      if (this.showApprove) {
        return {
          text: this.approvalText,
          category: this.isApproved ? 'secondary' : 'primary',
          variant: 'info',
          action: () => this.approve(),
        };
      } else if (this.showUnapprove) {
        return {
          text: s__('mrWidget|Revoke approval'),
          variant: 'warning',
          category: 'secondary',
          action: () => this.unapprove(),
        };
      }

      return null;
    },
  },
  created() {
    this.refreshApprovals()
      .then(() => {
        this.fetchingApprovals = false;
      })
      .catch(() =>
        createFlash({
          message: FETCH_ERROR,
        }),
      );
  },
  methods: {
    approve() {
      if (this.requirePasswordToApprove) {
        this.$root.$emit(BV_SHOW_MODAL, this.modalId);
        return;
      }

      this.updateApproval(
        () => this.service.approveMergeRequest(),
        () =>
          createFlash({
            message: APPROVE_ERROR,
          }),
      );
    },
    approveWithAuth(data) {
      this.updateApproval(
        () => this.service.approveMergeRequestWithAuth(data),
        (error) => {
          if (error && error.response && error.response.status === 401) {
            this.hasApprovalAuthError = true;
            return;
          }
          createFlash({
            message: APPROVE_ERROR,
          });
        },
      );
    },
    unapprove() {
      this.updateApproval(
        () => this.service.unapproveMergeRequest(),
        () =>
          createFlash({
            message: UNAPPROVE_ERROR,
          }),
      );
    },
    updateApproval(serviceFn, errFn) {
      this.isApproving = true;
      this.clearError();
      return serviceFn()
        .then((data) => {
          this.mr.setApprovals(data);
          eventHub.$emit('MRWidgetUpdateRequested');
          eventHub.$emit('ApprovalUpdated');
          this.$emit('updated');
        })
        .catch(errFn)
        .then(() => {
          this.isApproving = false;
        });
    },
  },
  FETCH_LOADING,
};
</script>
<template>
  <mr-widget-container>
    <div class="js-mr-approvals d-flex align-items-start align-items-md-center">
      <mr-widget-icon name="approval" />
      <div v-if="fetchingApprovals">{{ $options.FETCH_LOADING }}</div>
      <template v-else>
        <gl-button
          v-if="action"
          :variant="action.variant"
          :category="action.category"
          :loading="isApproving"
          class="mr-3"
          data-qa-selector="approve_button"
          @click="action.action"
        >
          {{ action.text }}
        </gl-button>
        <approvals-summary-optional
          v-if="isOptional"
          :can-approve="hasAction"
          :help-path="mr.approvalsHelpPath"
        />
        <approvals-summary
          v-else
          :approved="isApproved"
          :approvals-left="approvals.approvals_left || 0"
          :rules-left="approvals.approvalRuleNamesLeft"
          :approvers="approvedBy"
        />
        <slot
          :is-approving="isApproving"
          :approve-with-auth="approveWithAuth"
          :hasApproval-auth-error="hasApprovalAuthError"
        ></slot>
      </template>
    </div>
    <template #footer>
      <slot name="footer"></slot>
    </template>
  </mr-widget-container>
</template>
