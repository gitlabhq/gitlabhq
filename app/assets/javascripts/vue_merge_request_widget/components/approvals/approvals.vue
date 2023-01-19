<script>
import { GlButton, GlSprintf, GlLink } from '@gitlab/ui';
import { createAlert } from '~/flash';
import { BV_SHOW_MODAL } from '~/lib/utils/constants';
import { HTTP_STATUS_UNAUTHORIZED } from '~/lib/utils/http_status';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { s__, __ } from '~/locale';
import eventHub from '../../event_hub';
import approvalsMixin from '../../mixins/approvals';
import MrWidgetContainer from '../mr_widget_container.vue';
import MrWidgetIcon from '../mr_widget_icon.vue';
import { INVALID_RULES_DOCS_PATH } from '../../constants';
import ApprovalsSummary from './approvals_summary.vue';
import ApprovalsSummaryOptional from './approvals_summary_optional.vue';
import { FETCH_LOADING, FETCH_ERROR, APPROVE_ERROR, UNAPPROVE_ERROR } from './messages';
import { humanizeInvalidApproversRules } from './humanized_text';

export default {
  name: 'MRWidgetApprovals',
  components: {
    MrWidgetContainer,
    MrWidgetIcon,
    ApprovalsSummary,
    ApprovalsSummaryOptional,
    GlButton,
    GlSprintf,
    GlLink,
  },
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
    invalidRules() {
      return this.approvals.invalid_approvers_rules || [];
    },
    hasInvalidRules() {
      return this.approvals.merge_request_approvers_available && this.invalidRules.length;
    },
    invalidRulesText() {
      return humanizeInvalidApproversRules(this.invalidRules);
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
  created() {
    this.refreshApprovals()
      .then(() => {
        this.fetchingApprovals = false;
      })
      .catch(() =>
        this.alerts.push(
          createAlert({
            message: FETCH_ERROR,
          }),
        ),
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
        .then((data) => {
          this.mr.setApprovals(data);

          if (!window.gon?.features?.realtimeMrStatusChange) {
            eventHub.$emit('MRWidgetUpdateRequested');
            eventHub.$emit('ApprovalUpdated');
          }

          this.$emit('updated');
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
      'mrWidget|Approval rule %{rules} is invalid. GitLab has approved this rule automatically to unblock the merge request. %{link}',
    ),
    invalidRulesPlural: s__(
      'mrWidget|Approval rules %{rules} are invalid. GitLab has approved these rules automatically to unblock the merge request. %{link}',
    ),
    learnMore: __('Learn more.'),
  },
};
</script>
<template>
  <mr-widget-container>
    <div class="js-mr-approvals d-flex align-items-start align-items-md-center">
      <mr-widget-icon name="approval" />
      <div v-if="fetchingApprovals">{{ $options.FETCH_LOADING }}</div>
      <template v-else>
        <div class="gl-display-flex gl-flex-direction-column">
          <div class="gl-display-flex gl-flex-direction-row gl-align-items-center">
            <gl-button
              v-if="action"
              :variant="action.variant"
              :category="action.category"
              :loading="isApproving"
              class="gl-mr-5"
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
          </div>
          <div v-if="hasInvalidRules" class="gl-text-gray-400 gl-mt-2" data-testid="invalid-rules">
            <gl-sprintf :message="pluralizedRuleText">
              <template #rules>
                {{ invalidRulesText }}
              </template>
              <template #link>
                <gl-link :href="$options.linkToInvalidRules" target="_blank">
                  {{ $options.i18n.learnMore }}
                </gl-link>
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
    </div>
    <template #footer>
      <slot name="footer"></slot>
    </template>
  </mr-widget-container>
</template>
