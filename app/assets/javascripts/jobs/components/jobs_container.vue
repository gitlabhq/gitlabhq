<script>
  import _ from 'underscore';
  import CiIcon from '~/vue_shared/components/ci_icon.vue';
  import Icon from '~/vue_shared/components/icon.vue';
  import tooltip from '~/vue_shared/directives/tooltip';

  export default {
    components: {
      CiIcon,
      Icon,
    },
    directives: {
      tooltip,
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
      tooltipText(job) {
        return `${_.escape(job.name)} - ${job.status.tooltip}`;
      },
    },
  };
</script>
<template>
  <div class="js-jobs-container builds-container">
    <div
      v-for="job in jobs"
      :key="job.id"
      class="build-job"
      :class="{ retried: job.retried, active: isJobActive(job.id) }"
    >
      <a
        v-tooltip
        :href="job.status.details_path"
        :title="tooltipText(job)"
        data-container="body"
      >
        <icon
          v-if="isJobActive(job.id)"
          name="arrow-right"
          class="js-arrow-right icon-arrow-right"
        />

        <ci-icon :status="job.status" />

        <span>
          <template v-if="job.name">
            {{ job.name }}
          </template>
          <template v-else>
            {{ job.id }}
          </template>
        </span>

        <icon
          v-if="job.retried"
          name="retry"
          class="js-retry-icon"
        />
      </a>
    </div>
  </div>
</template>
