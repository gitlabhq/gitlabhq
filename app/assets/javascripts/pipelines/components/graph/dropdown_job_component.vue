<script>
import $ from 'jquery';
import JobNameComponent from './job_name_component.vue';
import JobComponent from './job_component.vue';
import tooltip from '../../../vue_shared/directives/tooltip';

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
 *       "icon": "retry",
 *       "title": "Retry",
 *       "path": "/root/ci-mock/builds/4256/retry",
 *       "method": "post"
 *     }
 *   }
 * }
 */
export default {
  directives: {
    tooltip,
  },

  components: {
    JobComponent,
    JobNameComponent,
  },

  props: {
    job: {
      type: Object,
      required: true,
    },
    requestFinishedFor: {
      type: String,
      required: false,
      default: '',
    },
  },

  computed: {
    tooltipText() {
      return `${this.job.name} - ${this.job.status.label}`;
    },
  },

  mounted() {
    this.stopDropdownClickPropagation();
  },

  methods: {
    /**
     * When the user right clicks or cmd/ctrl + click in the job name or the action icon
     * the dropdown should not be closed so we stop propagation
     * of the click event inside the dropdown.
     *
     * Since this component is rendered multiple times per page we need to guarantee we only
     * target the click event of this component.
     */
    stopDropdownClickPropagation() {
      $(
        '.js-grouped-pipeline-dropdown button, .js-grouped-pipeline-dropdown a.mini-pipeline-graph-dropdown-item',
        this.$el,
      ).on('click', e => {
        e.stopPropagation();
      });
    },
  },
};
</script>
<template>
  <div class="ci-job-dropdown-container">
    <button
      v-tooltip
      type="button"
      data-toggle="dropdown"
      data-container="body"
      class="dropdown-menu-toggle build-content"
      :title="tooltipText"
    >

      <job-name-component
        :name="job.name"
        :status="job.status"
      />

      <span class="dropdown-counter-badge">
        {{ job.size }}
      </span>
    </button>

    <ul class="dropdown-menu big-pipeline-graph-dropdown-menu js-grouped-pipeline-dropdown">
      <li class="scrollable-menu">
        <ul>
          <li
            v-for="(item, i) in job.jobs"
            :key="i"
          >
            <job-component
              :job="item"
              css-class-job-name="mini-pipeline-graph-dropdown-item"
              :request-finished-for="requestFinishedFor"
            />
          </li>
        </ul>
      </li>
    </ul>
  </div>
</template>
