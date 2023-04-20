<script>
import { GlButton, GlSprintf } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { STATUS_MERGED } from '~/issues/constants';
import { BV_SHOW_MODAL } from '~/lib/utils/constants';
import { HTTP_STATUS_UNAUTHORIZED } from '~/lib/utils/http_status';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { s__, __ } from '~/locale';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import eventHub from '../../event_hub';
import approvalsMixin from '../../mixins/approvals';
import StateContainer from '../state_container.vue';
import { INVALID_RULES_DOCS_PATH } from '../../constants';
import ApprovalsSummary from './approvals_summary.vue';
import ApprovalsSummaryOptional from './approvals_summary_optional.vue';
import { FETCH_LOADING, APPROVE_ERROR, UNAPPROVE_ERROR } from './messages';

export default {
  name: 'MRWidgetApprovals',
  components: {
    ApprovalsSummary,
    ApprovalsSummaryOptional,
    StateContainer,
    GlButton,
    GlSprintf,
  },
  mixins: [approvalsMixin, glFeatureFlagsMixin()],
  provide: {
    expandDetailsTooltip: __('Expand eligible approvers'),
    collapseDetailsTooltip: __('Collapse eligible approvers'),
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
    collapsed: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      hasApprovalAuthError: false,
      isApproving: false,
    };
  },
  computed: {
    isBasic() {
      return this.mr.approvalsWidgetType === 'base';
    },
    isApproved() {
      return Boolean(this.approvals.approved || this.approvedBy.length);
    },
    isOptional() {
      return this.isOptionalDefault !== null ? this.isOptionalDefault : !this.approvedBy.length;
    },
    hasAction() {
      return Boolean(this.action);
    },
    invalidRules() {
      return this.approvals.approvalState?.invalidApproversRules || [];
    },
    hasInvalidRules() {
      return this.mr.mergeRequestApproversAvailable && this.invalidRules.length;
    },
    invalidRulesText() {
      return this.invalidRules.length;
    },
    approvedBy() {
      return this.approvals.approvedBy?.nodes || [];
    },
    userHasApproved() {
      return this.approvedBy.some(
        (approver) => getIdFromGraphQLId(approver.id) === gon.current_user_id,
      );
    },
    userCanApprove() {
      return Boolean(this.approvals.userPermissions.canApprove);
    },
    showApprove() {
      return !this.userHasApproved && this.userCanApprove && this.mr.isOpen;
    },
    showUnapprove() {
      return this.userHasApproved && !this.userCanApprove && this.mr.state !== STATUS_MERGED;
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
          variant: 'confirm',
          action: () => this.approve(),
        };
      } else if (this.showUnapprove) {
        return {
          text: s__('mrWidget|Revoke approval'),
          variant: 'default',
          action: () => this.unapprove(),
        };
      }

      return null;
    },
    pluralizedRuleText() {
      return this.invalidRules.length > 1
        ? this.$options.i18n.invalidRulesPlural
        : this.$options.i18n.invalidRuleSingular;
    },
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
          this.alerts.push(
            createAlert({
              message: APPROVE_ERROR,
            }),
          ),
      );
    },
    approveWithAuth(data) {
      this.updateApproval(
        () => this.service.approveMergeRequestWithAuth(data),
        (error) => {
          if (error && error.response && error.response.status === HTTP_STATUS_UNAUTHORIZED) {
            this.hasApprovalAuthError = true;
            return;
          }
          this.alerts.push(
            createAlert({
              message: APPROVE_ERROR,
            }),
          );
        },
      );
    },
    unapprove() {
      this.updateApproval(
        () => this.service.unapproveMergeRequest(),
        () =>
          this.alerts.push(
            createAlert({
              message: UNAPPROVE_ERROR,
            }),
          ),
      );
    },
    updateApproval(serviceFn, errFn) {
      this.isApproving = true;
      this.clearError();
      return serviceFn()
        .then(() => {
          if (!window.gon?.features?.realtimeMrStatusChange) {
            eventHub.$emit('MRWidgetUpdateRequested');
            eventHub.$emit('ApprovalUpdated');
          }

          // TODO: Remove this line when we move to Apollo subscriptions
          this.$apollo.queries.approvals.refetch();
        })
        .catch(errFn)
        .then(() => {
          this.isApproving = false;
        });
    },
  },
  FETCH_LOADING,
  linkToInvalidRules: INVALID_RULES_DOCS_PATH,
  i18n: {
    invalidRuleSingular: s__(
      'mrWidget|%{rules} invalid rule has been approved automatically, as no one can approve it.',
    ),
    invalidRulesPlural: s__(
      'mrWidget|%{rules} invalid rules have been approved automatically, as no one can approve them.',
    ),
    learnMore: __('Learn more.'),
  },
};
</script>
<template>
  <div class="js-mr-approvals mr-section-container mr-widget-workflow">
    <state-container
      :is-loading="$apollo.queries.approvals.loading"
      :mr="mr"
      status="approval"
      is-collapsible
      collapse-on-desktop
      :collapsed="collapsed"
      @toggle="() => $emit('toggle')"
    >
      <template v-if="$apollo.queries.approvals.loading">{{ $options.FETCH_LOADING }}</template>
      <template v-else>
        <div class="gl-display-flex gl-flex-direction-column">
          <div class="gl-display-flex gl-flex-direction-row gl-align-items-center">
            <gl-button
              v-if="action"
              :variant="action.variant"
              :category="action.category"
              :loading="isApproving"
              class="gl-mr-3"
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
              :approval-state="approvals"
              :disable-committers-approval="disableCommittersApproval"
              :multiple-approval-rules-available="mr.multipleApprovalRulesAvailable"
            />
          </div>
          <div v-if="hasInvalidRules" class="gl-text-gray-400 gl-mt-2" data-testid="invalid-rules">
            <gl-sprintf :message="pluralizedRuleText">
              <template #rules>{{ invalidRulesText }}</template>
            </gl-sprintf>
          </div>
        </div>
        <slot
          :is-approving="isApproving"
          :approve-with-auth="approveWithAuth"
          :has-approval-auth-error="hasApprovalAuthError"
        ></slot>
      </template>
    </state-container>
    <slot name="footer"></slot>
  </div>
</template>
