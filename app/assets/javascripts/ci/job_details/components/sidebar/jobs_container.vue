<script>
import DetailRow from './sidebar_detail_row.vue';
import JobContainerItem from './job_container_item.vue';

export default {
  name: 'JobsContainer',
  components: {
    DetailRow,
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
  <detail-row :title="__('Related jobs')" heading-tag="h2" class="builds-container">
    <job-container-item
      v-for="job in jobs"
      :key="job.id"
      :job="job"
      :is-active="isJobActive(job.id)"
    />
  </detail-row>
</template>
