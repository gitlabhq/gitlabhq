<script>
import ActionComponent from './action_component.vue';
import JobNameComponent from './job_name_component.vue';
import tooltip from '../../../vue_shared/directives/tooltip';

/**
 * Renders the badge for the pipeline graph and the job's dropdown.
 *
 * The following object should be provided as `job`:
 *
 * {
 *   "id": 4256,
 *   "name": "test",
 *   "status": {
 *     "icon": "icon_status_success",
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
  components: {
    ActionComponent,
    JobNameComponent,
  },

  directives: {
    tooltip,
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

    isDropdown: {
      type: Boolean,
      required: false,
      default: false,
    },
  },

  computed: {
    status() {
      return this.job && this.job.status ? this.job.status : {};
    },

    tooltipText() {
      const textBuilder = [];

      if (this.job.name) {
        textBuilder.push(this.job.name);
      }

      if (this.job.name && this.status.tooltip) {
        textBuilder.push('-');
      }

      if (this.status.tooltip) {
        textBuilder.push(`${this.job.status.tooltip}`);
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
  },
};
</script>
<template>
  <div class="ci-job-component">
    <a
      v-tooltip
      v-if="status.has_details"
      :href="status.details_path"
      :title="tooltipText"
      :class="cssClassJobName"
      data-container="body"
      data-html="true"
      class="js-pipeline-graph-job-link"
    >

      <job-name-component
        :name="job.name"
        :status="job.status"
      />
    </a>

    <div
      v-else
      v-tooltip
      class="js-job-component-tooltip"
      :title="tooltipText"
      :class="cssClassJobName"
      data-html="true"
      data-container="body"
    >

      <job-name-component
        :name="job.name"
        :status="job.status"
      />
    </div>

    <action-component
      v-if="hasAction"
      :tooltip-text="status.action.title"
      :link="status.action.path"
      :action-icon="status.action.icon"
    />

  </div>
</template>
