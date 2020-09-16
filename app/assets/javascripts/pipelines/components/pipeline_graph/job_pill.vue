<script>
import tooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate.vue';

export default {
  components: {
    tooltipOnTruncate,
  },
  props: {
    jobName: {
      type: String,
      required: true,
    },
  },
};
</script>
<template>
  <tooltip-on-truncate :title="jobName" truncate-target="child" placement="top">
    <div
      class="gl-bg-white gl-text-center gl-text-truncate gl-rounded-pill gl-inset-border-1-green-600 gl-mb-3 gl-px-5 gl-py-2 pipeline-job-pill "
    >
      {{ jobName }}
    </div>
  </tooltip-on-truncate>
</template>
