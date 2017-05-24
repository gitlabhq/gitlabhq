<script>
  import jobNameComponent from './job_name_component.vue';
  import jobComponent from './job_component.vue';
  import tooltipMixin from '../../../vue_shared/mixins/tooltip';

  /**
   * Renders the dropdown for the pipeline graph.
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
    },

    mixins: [
      tooltipMixin,
    ],

    components: {
      jobComponent,
      jobNameComponent,
    },

    computed: {
      tooltipText() {
        return `${this.job.name} - ${this.job.status.label}`;
      },
    },
  };
</script>
<template>
  <div>
    <button
      type="button"
      data-toggle="dropdown"
      data-container="body"
      class="dropdown-menu-toggle build-content"
      :title="tooltipText"
      ref="tooltip">

      <job-name-component
        :name="job.name"
        :status="job.status" />

      <span class="dropdown-counter-badge">
        {{job.size}}
      </span>
    </button>

    <ul class="dropdown-menu big-pipeline-graph-dropdown-menu js-grouped-pipeline-dropdown">
      <li class="scrollable-menu">
        <ul>
          <li v-for="item in job.jobs">
            <job-component
              :job="item"
              :is-dropdown="true"
              css-class-job-name="mini-pipeline-graph-dropdown-item"
              />
          </li>
        </ul>
      </li>
    </ul>
  </div>
</template>
