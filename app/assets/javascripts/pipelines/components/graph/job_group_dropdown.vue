<script>
import { reportToSentry } from '../../utils';
import JobItem from './job_item.vue';

/**
 * Renders the dropdown for the pipeline graph.
 *
 * The object provided as `group` corresponds to app/serializers/job_group_entity.rb.
 *
 */
export default {
  components: {
    JobItem,
  },
  props: {
    group: {
      type: Object,
      required: true,
    },
    pipelineId: {
      type: Number,
      required: false,
      default: -1,
    },
    stageName: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    computedJobId() {
      return this.pipelineId > -1 ? `${this.group.name}-${this.pipelineId}` : '';
    },
    tooltipText() {
      const { name, status } = this.group;
      return `${name} - ${status.label}`;
    },
  },
  errorCaptured(err, _vm, info) {
    reportToSentry('job_group_dropdown', `error: ${err}, info: ${info}`);
  },
  methods: {
    pipelineActionRequestComplete() {
      this.$emit('pipelineActionRequestComplete');
    },
  },
};
</script>
<template>
  <div :id="computedJobId" class="ci-job-dropdown-container dropdown dropright">
    <button
      type="button"
      data-toggle="dropdown"
      data-display="static"
      class="dropdown-menu-toggle build-content gl-build-content gl-pipeline-job-width! gl-pr-4!"
    >
      <div class="gl-display-flex gl-align-items-center gl-justify-content-space-between">
        <job-item
          :dropdown-length="group.size"
          :group-tooltip="tooltipText"
          :job="group"
          :stage-name="stageName"
          @pipelineActionRequestComplete="pipelineActionRequestComplete"
        />

        <div class="gl-font-weight-100 gl-font-size-lg gl-ml-n4">{{ group.size }}</div>
      </div>
    </button>

    <ul class="dropdown-menu big-pipeline-graph-dropdown-menu js-grouped-pipeline-dropdown">
      <li class="scrollable-menu">
        <ul>
          <li v-for="job in group.jobs" :key="job.id">
            <job-item
              :dropdown-length="group.size"
              :job="job"
              css-class-job-name="mini-pipeline-graph-dropdown-item"
              @pipelineActionRequestComplete="pipelineActionRequestComplete"
            />
          </li>
        </ul>
      </li>
    </ul>
  </div>
</template>
