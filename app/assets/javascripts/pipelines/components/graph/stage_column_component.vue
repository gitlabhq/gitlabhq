<script>
import jobComponent from './job_component.vue';
import dropdownJobComponent from './dropdown_job_component.vue';

export default {
  props: {
    title: {
      type: String,
      required: true,
    },

    jobs: {
      type: Array,
      required: true,
    },
  },

  components: {
    jobComponent,
    dropdownJobComponent,
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
  <li class="stage-column">
    <div class="stage-name">
      {{title}}
    </div>
    <div class="builds-container">
      <ul>
        <li
          v-for="job in jobs"
          :key="job.id"
          class="build"
          :id="jobId(job)">

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
