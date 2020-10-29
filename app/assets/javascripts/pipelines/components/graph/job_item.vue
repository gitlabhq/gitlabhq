<script>
import { GlTooltipDirective, GlLink } from '@gitlab/ui';
import ActionComponent from './action_component.vue';
import JobNameComponent from './job_name_component.vue';
import { sprintf } from '~/locale';
import delayedJobMixin from '~/jobs/mixins/delayed_job_mixin';

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
  },
  computed: {
    boundary() {
      return this.dropdownLength === 1 ? 'viewport' : 'scrollParent';
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
  methods: {
    hideTooltips() {
      this.$root.$emit('bv::hide::tooltip');
    },
    pipelineActionRequestComplete() {
      this.$emit('pipelineActionRequestComplete');
    },
  },
};
</script>
<template>
  <div class="ci-job-component" data-qa-selector="job_item_container">
    <gl-link
      v-if="status.has_details"
      v-gl-tooltip="{ boundary, placement: 'bottom' }"
      :href="status.details_path"
      :title="tooltipText"
      :class="jobClasses"
      class="js-pipeline-graph-job-link qa-job-link menu-item"
      data-testid="job-with-link"
      @click.stop="hideTooltips"
    >
      <job-name-component :name="job.name" :status="job.status" />
    </gl-link>

    <div
      v-else
      v-gl-tooltip="{ boundary, placement: 'bottom' }"
      :title="tooltipText"
      :class="jobClasses"
      class="js-job-component-tooltip non-details-job-component"
      data-testid="job-without-link"
    >
      <job-name-component :name="job.name" :status="job.status" />
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
