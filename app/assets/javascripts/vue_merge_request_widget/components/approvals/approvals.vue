<script>
import { GlForm, GlButton, GlSprintf } from '@gitlab/ui';
import { createAlert } from '~/alert';
import csrf from '~/lib/utils/csrf';
import { STATUS_MERGED } from '~/issues/constants';
import { BV_SHOW_MODAL } from '~/lib/utils/constants';
import { HTTP_STATUS_UNAUTHORIZED } from '~/lib/utils/http_status';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { s__, __, sprintf } from '~/locale';
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
    pluralizedApprovedRuleText() {
      return this.invalidApprovedRules.length > 1
        ? this.$options.i18n.invalidRulesPlural
        : this.$options.i18n.invalidRuleSingular;
    },
    pluralizedFailedRuleText() {
      return this.invalidFailedRules.length > 1
        ? this.$options.i18n.invalidFailedRulesPlural
        : this.$options.i18n.invalidFailedRuleSingular;
    },
    pluralizedRuleText() {
      return [
        this.hasInvalidFailedRules
          ? sprintf(this.pluralizedFailedRuleText, { rules: this.invalidFailedRules.length })
          : null,
        this.hasInvalidApprovedRules
          ? sprintf(this.pluralizedApprovedRuleText, { rules: this.invalidApprovedRules.length })
          : null,
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
    invalidRuleSingular: s__('mrWidget|%{rules} invalid rule has been approved automatically'),
    invalidRulesPlural: s__('mrWidget|%{rules} invalid rules have been approved automatically'),
    invalidFailedRuleSingular: s__(
      "mrWidget|%{dangerStart}%{rules} rule can't be approved%{dangerEnd}",
    ),
    invalidFailedRulesPlural: s__(
      "mrWidget|%{dangerStart}%{rules} rules can't be approved%{dangerEnd}",
    ),
    learnMore: __('Learn more.'),
  },
};
</script>
<template>
  <div v-if="approvals" class="js-mr-approvals mr-section-container mr-widget-workflow">
    <state-container
      :is-loading="$apollo.queries.approvals.loading"
      :mr="mr"
      status="approval"
      is-collapsible
      collapse-on-desktop
      :collapsed="collapsed"
      :expand-details-tooltip="__('Expand eligible approvers')"
      :collapse-details-tooltip="__('Collapse eligible approvers')"
      @toggle="() => $emit('toggle')"
    >
      <template v-if="$apollo.queries.approvals.loading">{{ $options.FETCH_LOADING }}</template>
      <template v-else>
        <div class="gl-display-flex gl-flex-direction-column">
          <div class="gl-display-flex gl-flex-direction-column gl-sm-flex-direction-row gl-gap-3">
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
          <div v-if="hasInvalidRules" class="gl-text-secondary gl-mt-2" data-testid="invalid-rules">
            <gl-sprintf :message="pluralizedRuleText">
              <template #danger="{ content }">
                <span class="gl-font-weight-bold text-danger">{{ content }}</span>
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
