<script>
import JobContainerItem from './job_container_item.vue';

export default {
  components: {
    JobContainerItem,
  },

  props: {
    jobs: {
      type: Array,
      required: true,
    },
    jobId: {
      type: Number,
      required: true,
    },
  },
  methods: {
    isJobActive(currentJobId) {
      return this.jobId === currentJobId;
    },
  },
};
</script>
<template>
  <div class="block builds-container">
    <b class="gl-display-flex gl-mb-2 gl-font-weight-semibold">{{ __('Related jobs') }}</b>
    <job-container-item
      v-for="job in jobs"
      :key="job.id"
      :job="job"
      :is-active="isJobActive(job.id)"
    />
  </div>
</template>
