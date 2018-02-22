<script>
  import jobComponent from './job_component.vue';
  import dropdownJobComponent from './dropdown_job_component.vue';

  export default {
    components: {
      jobComponent,
      dropdownJobComponent,
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
      hasTriggeredBy: {
        type: Boolean,
        required: true,
      },
    },

    methods: {
      firstJob(list) {
        return list[0];
      },

      jobId(job) {
        return `ci-badge-${job.name}`;
      },
    },
  };
</script>
<template>
  <li
    class="stage-column"
    :class="stageConnectorClass">
    <div class="stage-name">
      {{ title }}
    </div>
    <div class="builds-container">
      <ul>
        <li
          v-for="(job, index) in jobs"
          :key="job.id"
          class="build"
          :class="{
            'left-connector': index === 0 && (!isFirstColumn || hasTriggeredBy)
          }"
          :id="jobId(job)"
        >

          <div class="curve"></div>

          <job-component
            v-if="job.size === 1"
            :job="job"
            css-class-job-name="build-content"
          />

          <dropdown-job-component
            v-if="job.size > 1"
            :job="job"
          />

        </li>
      </ul>
    </div>
  </li>
</template>
