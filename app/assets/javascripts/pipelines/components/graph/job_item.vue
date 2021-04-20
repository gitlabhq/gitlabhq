<script>
import { GlTooltipDirective, GlLink } from '@gitlab/ui';
import delayedJobMixin from '~/jobs/mixins/delayed_job_mixin';
import { BV_HIDE_TOOLTIP } from '~/lib/utils/constants';
import { sprintf } from '~/locale';
import CiIcon from '~/vue_shared/components/ci_icon.vue';
import { reportToSentry } from '../../utils';
import ActionComponent from '../jobs_shared/action_component.vue';
import JobNameComponent from '../jobs_shared/job_name_component.vue';
import { accessValue } from './accessors';
import { REST, SINGLE_JOB } from './constants';

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
  hoverClass: 'gl-shadow-x0-y0-b3-s1-blue-500',
  components: {
    ActionComponent,
    CiIcon,
    JobNameComponent,
    GlLink,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [delayedJobMixin],
  inject: {
    dataMethod: {
      default: REST,
    },
  },
  props: {
    job: {
      type: Object,
      required: true,
    },
    cssClassJobName: {
      type: String,
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
      return accessValue(this.dataMethod, 'detailsPath', this.status);
    },
    hasDetails() {
      return accessValue(this.dataMethod, 'hasDetails', this.status);
    },
    isSingleItem() {
      return this.type === SINGLE_JOB;
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
    relatedDownstreamHovered() {
      return this.job.name === this.sourceJobHovered;
    },
    relatedDownstreamExpanded() {
      return this.job.name === this.pipelineExpanded.jobName && this.pipelineExpanded.expanded;
    },
    jobClasses() {
      return this.relatedDownstreamHovered || this.relatedDownstreamExpanded
        ? `${this.$options.hoverClass} ${this.cssClassJobName}`
        : this.cssClassJobName;
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
    class="ci-job-component gl-display-flex gl-align-items-center gl-justify-content-space-between gl-w-full"
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
      class="js-pipeline-graph-job-link qa-job-link menu-item gl-text-gray-900 gl-active-text-decoration-none gl-focus-text-decoration-none gl-hover-text-decoration-none gl-w-full"
      :data-testid="testId"
      @click="jobItemClick"
      @mouseout="hideTooltips"
    >
      <div class="ci-job-name-component gl-display-flex gl-align-items-center">
        <ci-icon :size="24" :status="job.status" class="gl-line-height-0" />
        <div class="gl-pl-3 gl-display-flex gl-flex-direction-column gl-w-full">
          <div class="gl-text-truncate mw-70p gl-line-height-normal">{{ job.name }}</div>
          <div
            v-if="showStageName"
            data-testid="stage-name-in-job"
            class="gl-text-truncate mw-70p gl-font-sm gl-text-gray-500 gl-line-height-normal"
          >
            {{ stageName }}
          </div>
        </div>
      </div>
    </component>

    <action-component
      v-if="hasAction"
      :tooltip-text="status.action.title"
      :link="status.action.path"
      :action-icon="status.action.icon"
      class="gl-mr-1"
      data-qa-selector="action_button"
      @pipelineActionRequestComplete="pipelineActionRequestComplete"
    />
  </div>
</template>
