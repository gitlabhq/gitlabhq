<script>
import { GlTooltipDirective, GlLink } from '@gitlab/ui';
import delayedJobMixin from '~/jobs/mixins/delayed_job_mixin';
import { BV_HIDE_TOOLTIP } from '~/lib/utils/constants';
import { sprintf } from '~/locale';
import { reportToSentry } from '../../utils';
import ActionComponent from '../jobs_shared/action_component.vue';
import JobNameComponent from '../jobs_shared/job_name_component.vue';

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
    JobNameComponent,
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
      type: String,
      required: false,
      default: '',
    },
    dropdownLength: {
      type: Number,
      required: false,
      default: Infinity,
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
  },
  computed: {
    boundary() {
      return this.dropdownLength === 1 ? 'viewport' : 'scrollParent';
    },
    detailsPath() {
      return this.status.details_path;
    },
    hasDetails() {
      return this.status.has_details;
    },
    status() {
      return this.job && this.job.status ? this.job.status : {};
    },
    tooltipText() {
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
      return this.job.name === this.jobHovered;
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
    reportToSentry('pipelines_job_item', `pipelines_job_item error: ${err}, info: ${info}`);
  },
  methods: {
    hideTooltips() {
      this.$root.$emit(BV_HIDE_TOOLTIP);
    },
    pipelineActionRequestComplete() {
      this.$emit('pipelineActionRequestComplete');
    },
  },
};
</script>
<template>
  <div
    class="ci-job-component gl-display-flex gl-align-items-center gl-justify-content-space-between"
    data-qa-selector="job_item_container"
  >
    <gl-link
      v-if="hasDetails"
      v-gl-tooltip="{
        boundary: 'viewport',
        placement: 'bottom',
        customClass: 'gl-pointer-events-none',
      }"
      :href="detailsPath"
      :title="tooltipText"
      :class="jobClasses"
      class="js-pipeline-graph-job-link qa-job-link menu-item gl-text-gray-900 gl-active-text-decoration-none gl-focus-text-decoration-none gl-hover-text-decoration-none"
      data-testid="job-with-link"
      @click.stop="hideTooltips"
      @mouseout="hideTooltips"
    >
      <job-name-component :name="job.name" :status="job.status" :icon-size="24" />
    </gl-link>

    <div
      v-else
      v-gl-tooltip="{ boundary, placement: 'bottom', customClass: 'gl-pointer-events-none' }"
      :title="tooltipText"
      :class="jobClasses"
      class="js-job-component-tooltip non-details-job-component menu-item"
      data-testid="job-without-link"
      @mouseout="hideTooltips"
    >
      <job-name-component :name="job.name" :status="job.status" :icon-size="24" />
    </div>

    <action-component
      v-if="hasAction"
      :tooltip-text="status.action.title"
      :link="status.action.path"
      :action-icon="status.action.icon"
      data-qa-selector="action_button"
      @pipelineActionRequestComplete="pipelineActionRequestComplete"
    />
  </div>
</template>
