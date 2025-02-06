<script>
import { GlBadge, GlForm, GlFormCheckbox, GlLink, GlModal, GlTooltipDirective } from '@gitlab/ui';
import delayedJobMixin from '~/ci/mixins/delayed_job_mixin';
import { helpPagePath } from '~/helpers/help_page_helper';
import { BV_HIDE_TOOLTIP } from '~/lib/utils/constants';
import { __, s__, sprintf } from '~/locale';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import ActionComponent from '../../../common/private/job_action_component.vue';
import JobNameComponent from '../../../common/private/job_name_component.vue';
import { BRIDGE_KIND, RETRY_ACTION_TITLE, SINGLE_JOB, SKIP_RETRY_MODAL_KEY } from '../constants';

/**
 * Renders the badge for the pipeline graph and the job's dropdown.
 *
 * The following object should be provided as `job`:
 *
 * {
 *   "id": 4256,
 *   "name": "test",
 *   "status": {
 *     "icon": "status_success",
 *     "text": "passed",
 *     "label": "passed",
 *     "group": "success",
 *     "tooltip": "passed",
 *     "details_path": "/root/ci-mock/builds/4256",
 *     "action": {
 *       "icon": "retry",
 *       "title": "Retry",
 *       "path": "/root/ci-mock/builds/4256/retry",
 *       "method": "post"
 *     }
 *   }
 * }
 */

export default {
  confirmationModalDocLink: helpPagePath('/ci/pipelines/downstream_pipelines'),
  i18n: {
    bridgeBadgeText: __('Trigger job'),
    bridgeRetryText: s__(
      'PipelineGraph|Downstream pipeline might not display in the graph while the new downstream pipeline is being created.',
    ),
    unauthorizedTooltip: __('You are not authorized to run this manual job'),
    manualConfirmationModal: {
      title: s__('PipelineGraph|Are you sure you want to run %{jobName}?'),
      confirmationText: s__('PipelineGraph|Do you want to continue?'),
    },
    confirmationModal: {
      title: s__('PipelineGraph|Are you sure you want to retry %{jobName}?'),
      description: s__(
        'PipelineGraph|Retrying a trigger job will create a new downstream pipeline.',
      ),
      linkText: s__('PipelineGraph|What is a downstream pipeline?'),
      footer: __("Don't show this again"),
      actionCancel: { text: __('Cancel') },
      actionPrimary: { text: __('Retry') },
    },
    runAgainTooltipText: __('Run again'),
  },
  hoverClass: 'gl-shadow-x0-y0-b3-s1-blue-500',
  components: {
    ActionComponent,
    CiIcon,
    GlBadge,
    GlForm,
    GlFormCheckbox,
    GlLink,
    GlModal,
    JobNameComponent,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [delayedJobMixin],
  props: {
    job: {
      type: Object,
      required: true,
    },
    cssClassJobName: {
      type: [String, Array, Object],
      required: false,
      default: '',
    },
    hideTooltip: {
      type: Boolean,
      required: false,
      default: false,
    },
    jobHovered: {
      type: String,
      required: false,
      default: '',
    },
    pipelineExpanded: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    pipelineId: {
      type: Number,
      required: false,
      default: -1,
    },
    skipRetryModal: {
      type: Boolean,
      required: false,
      default: false,
    },
    sourceJobHovered: {
      type: String,
      required: false,
      default: '',
    },
    stageName: {
      type: String,
      required: false,
      default: '',
    },
    type: {
      type: String,
      required: false,
      default: SINGLE_JOB,
    },
    isLink: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  data() {
    return {
      currentSkipModalValue: this.skipRetryModal,
      showConfirmationModal: false,
      shouldTriggerActionClick: false,
    };
  },
  computed: {
    computedJobId() {
      return this.pipelineId > -1 ? `${this.job.name}-${this.pipelineId}` : '';
    },
    detailsPath() {
      if (this.isLink) {
        return this.status.detailsPath;
      }
      return null;
    },
    hasDetails() {
      return this.status.hasDetails;
    },
    hasRetryAction() {
      return Boolean(this.job?.status?.action?.title === RETRY_ACTION_TITLE);
    },
    isRetryableBridge() {
      return this.isBridge && this.hasRetryAction;
    },
    isSingleItem() {
      return this.type === SINGLE_JOB;
    },
    isBridge() {
      return this.kind === BRIDGE_KIND;
    },
    kind() {
      return this.job?.kind || '';
    },
    isFailed() {
      return this.job?.status?.group === 'failed';
    },
    shouldRenderLink() {
      return this.isLink && this.hasDetails;
    },
    nameComponent() {
      return this.shouldRenderLink ? 'gl-link' : 'div';
    },
    confirmationTitle() {
      const modal = this.hasManualConfirmationMessage
        ? this.$options.i18n.manualConfirmationModal
        : this.$options.i18n.confirmationModal;
      return sprintf(modal.title, {
        jobName: this.job.name,
      });
    },
    confirmationPrimaryText() {
      const modal = this.hasManualConfirmationMessage
        ? {
            actionPrimary: {
              text: sprintf(__('Yes, run %{jobName}'), {
                jobName: this.job.name,
              }),
            },
          }
        : this.$options.i18n.confirmationModal;
      return modal.actionPrimary;
    },
    showStageName() {
      return Boolean(this.stageName);
    },
    status() {
      return this.job && this.job.status ? this.job.status : {};
    },
    tooltipText() {
      if (this.hideTooltip) {
        return '';
      }

      const { tooltip: statusTooltip } = this.status;
      const { text: statusText } = this.status;

      if (statusTooltip) {
        if (this.isDelayedJob) {
          return sprintf(statusTooltip, { remainingTime: this.remainingTime });
        }
        return statusTooltip;
      }
      return statusText;
    },
    /**
     * Verifies if the provided job has an action path
     *
     * @return {Boolean}
     */
    hasAction() {
      return this.job.status && this.job.status.action && this.job.status.action.path;
    },
    hasManualConfirmationMessage() {
      return this.job.status.action.confirmationMessage !== null;
    },
    hasUnauthorizedManualAction() {
      return (
        !this.hasAction &&
        this.job.status?.group === 'manual' &&
        this.job.status?.label?.includes('(not allowed)')
      );
    },
    unauthorizedManualActionIcon() {
      /*
        The action object is not available when the user cannot run the action.
        So we can show the correct icon, extract the action name from the label instead:
        "manual play action (not allowed)" or "manual stop action (not allowed)"
      */
      return this.job.status?.label?.split(' ')[1];
    },
    relatedDownstreamHovered() {
      return this.job.name === this.sourceJobHovered;
    },
    relatedDownstreamExpanded() {
      return this.job.name === this.pipelineExpanded.jobName && this.pipelineExpanded.expanded;
    },
    jobClasses() {
      return [
        {
          [this.$options.hoverClass]:
            this.relatedDownstreamHovered || this.relatedDownstreamExpanded,
        },
        { 'gl-rounded-lg': this.isBridge },
        this.cssClassJobName,
        {
          'ci-job-item-failed': this.isSingleItem && this.isFailed,
        },
      ];
    },
    withConfirmationModal() {
      return (this.isRetryableBridge && !this.skipRetryModal) || this.hasManualConfirmationMessage;
    },
    manualConfirmationMessage() {
      return sprintf(__('Custom confirmation message: %{message}'), {
        message: this.job.status.action.confirmationMessage,
      });
    },
    jobActionTooltipText() {
      const { group } = this.status;
      const { title, icon } = this.status.action;

      return icon === 'retry' && group === 'success'
        ? this.$options.i18n.runAgainTooltipText
        : title;
    },
  },
  watch: {
    skipRetryModal(val) {
      this.currentSkipModalValue = val;
      this.shouldTriggerActionClick = false;
    },
  },
  methods: {
    handleConfirmationModalPreferences() {
      if (this.currentSkipModalValue) {
        this.$emit('setSkipRetryModal');
        localStorage.setItem(SKIP_RETRY_MODAL_KEY, String(this.currentSkipModalValue));
      }
    },
    hideTooltips() {
      this.$root.$emit(BV_HIDE_TOOLTIP);
    },
    jobItemClick(evt) {
      if (this.isSingleItem) {
        /*
          This is so the jobDropdown still toggles. Issue to refactor:
          https://gitlab.com/gitlab-org/gitlab/-/issues/267117
        */
        evt.stopPropagation();
      }

      this.hideTooltips();
    },
    pipelineActionRequestComplete() {
      this.$emit('pipelineActionRequestComplete');

      if (this.isBridge) {
        this.$toast.show(this.$options.i18n.bridgeRetryText);
      }
    },
    executePendingAction() {
      this.shouldTriggerActionClick = true;
    },
    showActionConfirmationModal() {
      this.showConfirmationModal = true;
    },
    toggleSkipRetryModalCheckbox() {
      this.currentSkipModalValue = !this.currentSkipModalValue;
    },
  },
};
</script>
<template>
  <div
    :id="computedJobId"
    class="ci-job-component gl-pipeline-job-width gl-flex gl-justify-between"
    data-testid="ci-job-item"
  >
    <component
      :is="nameComponent"
      v-gl-tooltip.viewport.left="{ customClass: 'ci-job-component-tooltip' }"
      :title="tooltipText"
      :href="detailsPath"
      :class="jobClasses"
      class="menu-item gl-w-full gl-rounded-base gl-text-strong hover:gl-bg-strong hover:gl-no-underline focus:gl-bg-strong focus:gl-no-underline active:gl-no-underline dark:hover:gl-bg-gray-200 dark:focus:gl-bg-gray-200"
      data-testid="ci-job-item-content"
      @click="jobItemClick"
      @mouseout="hideTooltips"
    >
      <div class="gl-flex gl-grow gl-items-center">
        <ci-icon :status="job.status" :use-link="false" :show-tooltip="false" />
        <div class="gl-pipeline-job-width gl-flex gl-flex-col gl-pl-3 gl-pr-3">
          <div
            class="gl-truncate gl-pr-9 gl-text-left gl-leading-normal gl-text-default"
            :title="job.name"
          >
            {{ job.name }}
          </div>
          <div
            v-if="showStageName"
            data-testid="stage-name-in-job"
            class="gl-truncate gl-pr-9 gl-text-left gl-text-sm gl-leading-normal gl-text-subtle"
          >
            {{ stageName }}
          </div>
        </div>
      </div>
      <gl-badge
        v-if="isBridge"
        class="gl-ml-7 gl-mt-3"
        variant="info"
        data-testid="job-bridge-badge"
      >
        {{ $options.i18n.bridgeBadgeText }}
      </gl-badge>
    </component>

    <action-component
      v-if="hasAction"
      :tooltip-text="jobActionTooltipText"
      :link="status.action.path"
      :action-icon="status.action.icon"
      class="gl-mr-1"
      :should-trigger-click="shouldTriggerActionClick"
      :with-confirmation-modal="withConfirmationModal"
      @actionButtonClicked="handleConfirmationModalPreferences"
      @pipelineActionRequestComplete="pipelineActionRequestComplete"
      @showActionConfirmationModal="showActionConfirmationModal"
      @focus.native="hideTooltips"
    />
    <action-component
      v-if="hasUnauthorizedManualAction"
      disabled
      :tooltip-text="$options.i18n.unauthorizedTooltip"
      :action-icon="unauthorizedManualActionIcon"
      :link="`unauthorized-${computedJobId}`"
      class="gl-mr-1"
    />
    <gl-modal
      v-if="showConfirmationModal"
      ref="modal"
      v-model="showConfirmationModal"
      modal-id="action-confirmation-modal"
      :title="confirmationTitle"
      :action-cancel="$options.i18n.confirmationModal.actionCancel"
      :action-primary="confirmationPrimaryText"
      @primary="executePendingAction"
      @close="handleConfirmationModalPreferences"
      @hide="handleConfirmationModalPreferences"
    >
      <div v-if="job.status.action.confirmationMessage">
        <p>{{ manualConfirmationMessage }}</p>
        <p>{{ $options.i18n.manualConfirmationModal.confirmationText }}</p>
      </div>
      <div v-else>
        <p class="gl-mb-1">{{ $options.i18n.confirmationModal.description }}</p>
        <gl-link :href="$options.confirmationModalDocLink" target="_blank"
          >{{ $options.i18n.confirmationModal.linkText }}
        </gl-link>
        <div class="gl-mt-4 gl-flex">
          <gl-form>
            <gl-form-checkbox class="gl-min-h-0" @input="toggleSkipRetryModalCheckbox" />
          </gl-form>
          <p class="gl-m-0">{{ $options.i18n.confirmationModal.footer }}</p>
        </div>
      </div>
    </gl-modal>
  </div>
</template>
