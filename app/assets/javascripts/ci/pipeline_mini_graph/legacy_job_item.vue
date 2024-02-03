<script>
import { GlTooltipDirective, GlLink } from '@gitlab/ui';
import ActionComponent from '~/ci/common/private/job_action_component.vue';
import JobNameComponent from '~/ci/common/private/job_name_component.vue';
import { ICONS } from '~/ci/constants';
import delayedJobMixin from '~/ci/mixins/delayed_job_mixin';
import { s__, sprintf } from '~/locale';
import { reportToSentry } from '~/ci/utils';

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
    runAgainTooltipText: s__('Pipeline|Run again'),
  },
  tooltipConfig: {
    boundary: 'viewport',
    placement: 'top',
    customClass: 'gl-pointer-events-none',
  },
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
      return this.status?.details_path;
    },
    hasDetails() {
      return this.status?.has_details;
    },
    status() {
      return this.job?.status ? this.job.status : {};
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
    hasJobAction() {
      return Boolean(this.job?.status?.action?.path);
    },
    jobActionTooltipText() {
      const { group } = this.status;
      const { title, icon } = this.status.action;

      return icon === ICONS.RETRY && group === ICONS.SUCCESS
        ? this.$options.i18n.runAgainTooltipText
        : title;
    },
  },
  errorCaptured(err, _vm, info) {
    reportToSentry('pipelines_job_item', `pipelines_job_item error: ${err}, info: ${info}`);
  },
};
</script>
<template>
  <div
    class="ci-job-component gl-display-flex gl-align-items-center gl-justify-content-space-between"
  >
    <gl-link
      v-if="hasDetails"
      v-gl-tooltip="$options.tooltipConfig"
      :href="detailsPath"
      :title="tooltipText"
      :class="cssClassJobName"
      class="js-pipeline-graph-job-link menu-item gl-text-gray-900 gl-active-text-decoration-none gl-focus-text-decoration-none gl-hover-text-decoration-none"
      data-testid="job-with-link"
    >
      <job-name-component :name="job.name" :status="job.status" />
    </gl-link>

    <div
      v-else
      v-gl-tooltip="{ boundary, placement: 'bottom', customClass: 'gl-pointer-events-none' }"
      :title="tooltipText"
      :class="cssClassJobName"
      class="js-job-component-tooltip non-details-job-component menu-item"
      data-testid="job-without-link"
    >
      <job-name-component :name="job.name" :status="job.status" />
    </div>

    <action-component
      v-if="hasJobAction"
      :tooltip-text="jobActionTooltipText"
      :link="status.action.path"
      :action-icon="status.action.icon"
    />
  </div>
</template>
