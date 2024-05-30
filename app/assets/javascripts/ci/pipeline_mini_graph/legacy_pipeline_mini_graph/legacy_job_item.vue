<script>
import { GlDisclosureDropdownItem, GlTooltipDirective } from '@gitlab/ui';
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
  components: {
    ActionComponent,
    JobNameComponent,
    GlDisclosureDropdownItem,
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
    detailsPath() {
      return this.status?.details_path;
    },
    hasDetails() {
      return this.status?.has_details;
    },
    item() {
      return {
        text: this.job.name,
        href: this.hasDetails ? this.detailsPath : '',
      };
    },
    status() {
      return this.job?.status ? this.job.status : {};
    },
    tooltipText() {
      const textBuilder = [];
      const { tooltip: statusTooltip } = this.status;

      if (statusTooltip) {
        const statusText = statusTooltip.charAt(0).toUpperCase() + statusTooltip.slice(1);

        if (this.isDelayedJob) {
          textBuilder.push(sprintf(statusText, { remainingTime: this.remainingTime }));
        } else {
          textBuilder.push(statusText);
        }
      } else {
        textBuilder.push(this.status?.text);
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
    testid() {
      return this.hasDetails ? 'job-with-link' : 'job-without-link';
    },
  },
  errorCaptured(err, _vm, info) {
    reportToSentry('pipelines_job_item', `pipelines_job_item error: ${err}, info: ${info}`);
  },
};
</script>
<template>
  <gl-disclosure-dropdown-item
    :item="item"
    class="ci-job-component"
    :class="[
      cssClassJobName,
      {
        'gl-text-gray-900 gl-active-text-decoration-none gl-focus-text-decoration-none gl-hover-text-decoration-none': hasDetails,
        'js-job-component-tooltip non-details-job-component': !hasDetails,
      },
    ]"
    :data-testid="testid"
  >
    <template #list-item>
      <div
        class="gl-display-flex gl-align-items-center gl-justify-content-space-between -gl-mt-2 -gl-mb-2 -gl-ml-2"
      >
        <job-name-component
          v-gl-tooltip.viewport.left
          :title="tooltipText"
          :name="job.name"
          :status="job.status"
          data-testid="job-name"
        />

        <action-component
          v-if="hasJobAction"
          :tooltip-text="jobActionTooltipText"
          :link="status.action.path"
          :action-icon="status.action.icon"
          class="-gl-mt-2 -gl-mr-2"
        />
      </div>
    </template>
  </gl-disclosure-dropdown-item>
</template>
