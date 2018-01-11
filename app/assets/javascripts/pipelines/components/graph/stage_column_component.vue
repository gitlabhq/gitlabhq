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

<<<<<<< HEAD
      jobs: {
        type: Array,
        required: true,
      },

=======
    props: {
      title: {
        type: String,
        required: true,
      },

      jobs: {
        type: Array,
        required: true,
      },

>>>>>>> upstream/master
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
<<<<<<< HEAD
      hasTriggeredBy: {
        type: Boolean,
        required: true,
      },
=======
>>>>>>> upstream/master
    },

    methods: {
      firstJob(list) {
        return list[0];
      },
<<<<<<< HEAD

      jobId(job) {
        return `ci-badge-${job.name}`;
=======

      jobId(job) {
        return `ci-badge-${job.name}`;
      },

      buildConnnectorClass(index) {
        return index === 0 && !this.isFirstColumn ? 'left-connector' : '';
>>>>>>> upstream/master
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
<<<<<<< HEAD
          :class="{
            'left-connector': index === 0 && (!isFirstColumn || hasTriggeredBy)
          }"
          :id="jobId(job)">
=======
          :class="buildConnnectorClass(index)"
          :id="jobId(job)"
        >
>>>>>>> upstream/master

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
