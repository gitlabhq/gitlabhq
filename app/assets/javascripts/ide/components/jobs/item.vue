<script>
import CiIcon from '../../../vue_shared/components/ci_icon.vue';

export default {
  components: {
    CiIcon,
  },
  props: {
    job: {
      type: Object,
      required: true,
    },
  },
  computed: {
    jobId() {
      return `#${this.job.id}`;
    },
  },
};
</script>

<template>
  <div class="ide-job-item">
    <ci-icon
      :status="job.status"
      :borderless="true"
      :size="24"
    />
    <span class="prepend-left-8">
      {{ job.name }}
      <a
        :href="job.path"
        target="_blank"
        v-text="jobId"
      >
      </a>
    </span>
  </div>
</template>

<style scoped>
.ide-job-item {
  display: flex;
  padding: 16px;
}

.ide-job-item:not(:last-child) {
  border-bottom: 1px solid #e5e5e5;
}

.ide-job-item .ci-status-icon {
  display: flex;
  justify-content: center;
  height: 20px;
  margin-top: -2px;
  overflow: hidden;
}
</style>
