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
    job: {
      type: Object,
      required: true,
    },
    isActive: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    tooltipText() {
      return `${this.job.name} - ${this.job.status.tooltip}`;
    },
  },
};
</script>

<template>
  <div
    class="build-job"
    :class="{
      retried: job.retried,
      active: isActive
    }"
  >
    <a
      v-tooltip
      :href="job.status.details_path"
      :title="tooltipText"
      data-container="body"
      data-boundary="viewport"
      class="js-job-link"
    >
      <icon
        v-if="isActive"
        name="arrow-right"
        class="js-arrow-right icon-arrow-right"
      />

      <ci-icon :status="job.status" />

      <span>{{ job.name ? job.name : job.id }}</span>

      <icon
        v-if="job.retried"
        name="retry"
        class="js-retry-icon"
      />
    </a>
  </div>
</template>
