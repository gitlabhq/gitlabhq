<script>
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
    },
  };
</script>
<template>
  <div class="builds-container">
    <div
      class="build-job"
    >
      <a
        v-tooltip
        v-for="job in jobs"
        :key="job.id"
        :href="job.path"
        :title="job.tooltip"
        :class="{ active: job.active, retried: job.retried }"
      >
        <icon
          v-if="job.active"
          name="arrow-right"
          class="js-arrow-right"
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
