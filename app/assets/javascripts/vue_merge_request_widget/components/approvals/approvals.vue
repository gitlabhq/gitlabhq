<script>
import { GlForm, GlButton, GlSprintf } from '@gitlab/ui';
import { createAlert } from '~/alert';
import csrf from '~/lib/utils/csrf';
import { STATUS_MERGED } from '~/issues/constants';
import { BV_SHOW_MODAL } from '~/lib/utils/constants';
import { HTTP_STATUS_UNAUTHORIZED } from '~/lib/utils/http_status';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { s__, __, n__, sprintf } from '~/locale';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
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
    GlForm,
  },
  csrf,
  mixins: [approvalsMixin, glFeatureFlagsMixin()],
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
    hasAllApprovals: {
      type: Boolean,
      required: false,
      default: false,
    },
    actionButtons: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data() {
    return {
      hasApprovalAuthError: false,
      isApproving: false,
      userPermissions: {},
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.approvals.loading || !this.approvals;
    },
    isBasic() {
      return this.mr.approvalsWidgetType === 'base';
    },
    isApproved() {
      return this.hasAllApprovals;
    },
    isOptional() {
      return this.isOptionalDefault !== null ? this.isOptionalDefault : !this.approvedBy.length;
    },
    hasAction() {
      return Boolean(this.action);
    },
    invalidRules() {
      return this.approvals.approvalState?.rules?.filter((rule) => rule.invalid) || [];
    },
    invalidApprovedRules() {
      return this.invalidRules.filter((rule) => rule.allowMergeWhenInvalid);
    },
    invalidFailedRules() {
      return this.invalidRules.filter((rule) => !rule.allowMergeWhenInvalid);
    },
    hasInvalidRules() {
      return this.mr.mergeRequestApproversAvailable && this.invalidRules.length;
    },
    hasInvalidApprovedRules() {
      return this.mr.mergeRequestApproversAvailable && this.invalidApprovedRules.length;
    },
    hasInvalidFailedRules() {
      return this.mr.mergeRequestApproversAvailable && this.invalidFailedRules.length;
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
    showApproveButton() {
      return (!this.requireSamlAuthToApprove || this.showUnapprove) && this.action;
    },
    approvalText() {
      // Repeating a text of this to keep i18n easier to do (vs, construcing a compound string)
      if (this.requireSamlAuthToApprove) {
        return this.isApproved && this.approvedBy.length > 0
          ? s__('mrWidget|Approve additionally with SAML')
          : s__('mrWidget|Approve with SAML');
      }

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
      }
      if (this.showUnapprove) {
        return {
          text: s__('mrWidget|Revoke approval'),
          variant: 'default',
          action: () => this.unapprove(),
        };
      }

      return null;
    },
    pluralizedFailedRuleText() {
      return sprintf(
        n__(
          "mrWidget|%{dangerStart}1 rule can't be approved%{dangerEnd}",
          "mrWidget|%{dangerStart}%{count} rules can't be approved%{dangerEnd}",
          this.invalidFailedRules.length,
        ),
        { count: this.invalidFailedRules.length },
      );
    },
    pluralizedApprovedRuleText() {
      return sprintf(
        n__(
          'mrWidget|1 invalid rule has been approved automatically',
          'mrWidget|%{count} invalid rules have been approved automatically',
          this.invalidApprovedRules.length,
        ),
        { count: this.invalidApprovedRules.length },
      );
    },
    pluralizedRuleText() {
      return [
        this.hasInvalidFailedRules ? this.pluralizedFailedRuleText : null,
        this.hasInvalidApprovedRules ? this.pluralizedApprovedRuleText : null,
      ]
        .filter((text) => Boolean(text))
        .join(', ')
        .concat('.');
    },
    samlApprovalPath() {
      return this.mr.samlApprovalPath;
    },
    requireSamlAuthToApprove() {
      return this.mr.requireSamlAuthToApprove;
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
    approveWithSamlAuth() {
      // Intentionally direct to SAML Identity Provider for renewed authorization even if SSO session exists
      this.$refs.form.$el.submit();
    },
    approveWithAuth(data) {
      this.updateApproval(
        () => this.service.approveMergeRequestWithAuth(data),
        (error) => {
          if (error?.response?.status === HTTP_STATUS_UNAUTHORIZED) {
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
    learnMore: __('Learn more.'),
  },
};
</script>
<template>
  <div v-if="approvals" class="js-mr-approvals mr-section-container">
    <state-container
      :is-loading="isLoading"
      :mr="mr"
      status="approval"
      is-collapsible
      collapse-on-desktop
      :collapsed="collapsed"
      :expand-details-tooltip="__('Expand eligible approvers')"
      :collapse-details-tooltip="__('Collapse eligible approvers')"
      :actions="actionButtons"
      @toggle="() => $emit('toggle')"
    >
      <template v-if="isLoading">{{ $options.FETCH_LOADING }}</template>
      <template v-else>
        <div class="gl-flex gl-flex-col">
          <div
            class="gl-flex gl-flex-col gl-flex-wrap gl-items-baseline gl-gap-3 sm:gl-flex-row sm:gl-items-center"
          >
            <div v-if="requireSamlAuthToApprove && showApprove">
              <gl-form
                ref="form"
                :action="samlApprovalPath"
                method="post"
                data-testid="approve-form"
              >
                <gl-button
                  v-if="action"
                  :variant="action.variant"
                  size="small"
                  :category="action.category"
                  :loading="isApproving"
                  data-testid="approve-button"
                  type="submit"
                >
                  {{ action.text }}
                </gl-button>
                <input :value="$options.csrf.token" type="hidden" name="authenticity_token" />
              </gl-form>
            </div>
            <gl-button
              v-if="showApproveButton"
              :variant="action.variant"
              size="small"
              :category="action.category"
              :loading="isApproving"
              data-testid="approve-button"
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
          <div v-if="hasInvalidRules" class="gl-mt-2 gl-text-subtle" data-testid="invalid-rules">
            <gl-sprintf :message="pluralizedRuleText">
              <template #danger="{ content }">
                <span class="gl-font-bold gl-text-danger">{{ content }}</span>
              </template>
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
