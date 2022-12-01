<script>
import { GlBadge, GlLink, GlTooltipDirective } from '@gitlab/ui';
import delayedJobMixin from '~/jobs/mixins/delayed_job_mixin';
import { BV_HIDE_TOOLTIP } from '~/lib/utils/constants';
import { sprintf, __ } from '~/locale';
import CiIcon from '~/vue_shared/components/ci_icon.vue';
import { reportToSentry } from '../../utils';
import ActionComponent from '../jobs_shared/action_component.vue';
import JobNameComponent from '../jobs_shared/job_name_component.vue';
import { BRIDGE_KIND, SINGLE_JOB } from './constants';

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
  i18n: {
    bridgeBadgeText: __('Trigger job'),
    unauthorizedTooltip: __('You are not authorized to run this manual job'),
  },
  hoverClass: 'gl-shadow-x0-y0-b3-s1-blue-500',
  components: {
    ActionComponent,
    CiIcon,
    JobNameComponent,
    GlBadge,
    GlLink,
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
    dropdownLength: {
      type: Number,
      required: false,
      default: Infinity,
    },
    groupTooltip: {
      type: String,
      required: false,
      default: '',
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
  },
  computed: {
    boundary() {
      return this.dropdownLength === 1 ? 'viewport' : 'scrollParent';
    },
    computedJobId() {
      return this.pipelineId > -1 ? `${this.job.name}-${this.pipelineId}` : '';
    },
    detailsPath() {
      return this.status.detailsPath;
    },
    hasDetails() {
      return this.status.hasDetails;
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
    nameComponent() {
      return this.hasDetails ? 'gl-link' : 'div';
    },
    showStageName() {
      return Boolean(this.stageName);
    },
    status() {
      return this.job && this.job.status ? this.job.status : {};
    },
    testId() {
      return this.hasDetails ? 'job-with-link' : 'job-without-link';
    },
    tooltipText() {
      if (this.groupTooltip) {
        return this.groupTooltip;
      }

      const textBuilder = [];
      const { name: jobName } = this.job;

      if (jobName) {
        textBuilder.push(jobName);
      }

      const { tooltip: statusTooltip } = this.status;
      if (jobName && statusTooltip) {
        textBuilder.push('-');
      }

      if (statusTooltip) {
        if (this.isDelayedJob) {
          textBuilder.push(sprintf(statusTooltip, { remainingTime: this.remainingTime }));
        } else {
          textBuilder.push(statusTooltip);
        }
      }

      return textBuilder.join(' ');
    },
    /**
     * Verifies if the provided job has an action path
     *
     * @return {Boolean}
     */
    hasAction() {
      return this.job.status && this.job.status.action && this.job.status.action.path;
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
          [`job-${this.status.group}`]: this.isSingleItem,
        },
      ];
    },
  },
  errorCaptured(err, _vm, info) {
    reportToSentry('job_item', `error: ${err}, info: ${info}`);
  },
  methods: {
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
    },
  },
};
</script>
<template>
  <div
    :id="computedJobId"
    class="ci-job-component gl-display-flex gl-justify-content-space-between gl-pipeline-job-width"
    data-qa-selector="job_item_container"
  >
    <component
      :is="nameComponent"
      v-gl-tooltip="{
        boundary: 'viewport',
        placement: 'bottom',
        customClass: 'gl-pointer-events-none',
      }"
      :title="tooltipText"
      :class="jobClasses"
      :href="detailsPath"
      class="js-pipeline-graph-job-link menu-item gl-text-gray-900 gl-active-text-decoration-none gl-focus-text-decoration-none gl-hover-text-decoration-none gl-w-full"
      :data-testid="testId"
      data-qa-selector="job_link"
      @click="jobItemClick"
      @mouseout="hideTooltips"
    >
      <div class="gl-display-flex gl-align-items-center gl-flex-grow-1">
        <ci-icon :size="24" :status="job.status" class="gl-line-height-0" />
        <div class="gl-pl-3 gl-pr-3 gl-display-flex gl-flex-direction-column gl-pipeline-job-width">
          <div class="gl-text-truncate gl-pr-9 gl-line-height-normal">{{ job.name }}</div>
          <div
            v-if="showStageName"
            data-testid="stage-name-in-job"
            class="gl-text-truncate gl-pr-9 gl-font-sm gl-text-gray-500 gl-line-height-normal"
          >
            {{ stageName }}
          </div>
        </div>
      </div>
      <gl-badge v-if="isBridge" class="gl-mt-3" variant="info" size="sm">
        {{ $options.i18n.bridgeBadgeText }}
      </gl-badge>
    </component>

    <action-component
      v-if="hasAction"
      :tooltip-text="status.action.title"
      :link="status.action.path"
      :action-icon="status.action.icon"
      class="gl-mr-1"
      data-qa-selector="job_action_button"
      @pipelineActionRequestComplete="pipelineActionRequestComplete"
    />
    <action-component
      v-if="hasUnauthorizedManualAction"
      disabled
      :tooltip-text="$options.i18n.unauthorizedTooltip"
      :action-icon="unauthorizedManualActionIcon"
      :link="`unauthorized-${computedJobId}`"
      class="gl-mr-1"
    />
  </div>
</template>
