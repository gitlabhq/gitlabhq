<script>
import _ from 'underscore';
import JobComponent from './job_component.vue';
import DropdownJobComponent from './dropdown_job_component.vue';

export default {
  components: {
    JobComponent,
    DropdownJobComponent,
  },
  props: {
    title: {
      type: String,
      required: true,
    },

    jobs: {
      type: Array,
      required: true,
    },

    isFirstColumn: {
      type: Boolean,
      required: false,
      default: false,
    },

    stageConnectorClass: {
      type: String,
      required: false,
      default: '',
    },
  },

  methods: {
    firstJob(list) {
      return list[0];
    },

    jobId(job) {
      return `ci-badge-${_.escape(job.name)}`;
    },

    buildConnnectorClass(index) {
      return index === 0 && !this.isFirstColumn ? 'left-connector' : '';
    },

    pipelineActionRequestComplete() {
      this.$emit('refreshPipelineGraph');
    },
  },
};
</script>
<template>
  <li
    :class="stageConnectorClass"
    class="stage-column">
    <div class="stage-name">
      {{ title }}
    </div>
    <div class="builds-container">
      <ul>
        <li
          v-for="(job, index) in jobs"
          :key="job.id"
          :class="buildConnnectorClass(index)"
          :id="jobId(job)"
          class="build"
        >

          <div class="curve"></div>

          <job-component
            v-if="job.size === 1"
            :job="job"
            css-class-job-name="build-content"
            @pipelineActionRequestComplete="pipelineActionRequestComplete"
          />

          <dropdown-job-component
            v-if="job.size > 1"
            :job="job"
            @pipelineActionRequestComplete="pipelineActionRequestComplete"
          />

        </li>
      </ul>
    </div>
  </li>
</template>
