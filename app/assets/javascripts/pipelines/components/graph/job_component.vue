<script>
  import actionComponent from './action_component.vue';
  import dropdownActionComponent from './dropdown_action_component.vue';
  import jobNameComponent from './job_name_component.vue';
  import tooltipMixin from '../../../vue_shared/mixins/tooltip';

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
   *     "details_path": "/root/ci-mock/builds/4256",
   *     "action": {
   *       "icon": "icon_action_retry",
   *       "title": "Retry",
   *       "path": "/root/ci-mock/builds/4256/retry",
   *       "method": "post"
   *     }
   *   }
   * }
   */

  export default {
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

    components: {
      actionComponent,
      dropdownActionComponent,
      jobNameComponent,
    },

    mixins: [
      tooltipMixin,
    ],

    computed: {
      tooltipText() {
        return `${this.job.name} - ${this.job.status.label}`;
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
  <div>
    <a
      v-if="job.status.details_path"
      :href="job.status.details_path"
      :title="tooltipText"
      :class="cssClassJobName"
      ref="tooltip"
      data-toggle="tooltip"
      data-container="body">

      <job-name-component
        :name="job.name"
        :status="job.status"
        />
    </a>

    <div
      v-else
      :title="tooltipText"
      :class="cssClassJobName"
      ref="tooltip"
      data-toggle="tooltip"
      data-container="body">

      <job-name-component
        :name="job.name"
        :status="job.status"
        />
    </div>

    <action-component
      v-if="hasAction && !isDropdown"
      :tooltip-text="job.status.action.title"
      :link="job.status.action.path"
      :action-icon="job.status.action.icon"
      :action-method="job.status.action.method"
      />

    <dropdown-action-component
      v-if="hasAction && isDropdown"
      :tooltip-text="job.status.action.title"
      :link="job.status.action.path"
      :action-icon="job.status.action.icon"
      :action-method="job.status.action.method"
      />
  </div>
</template>
