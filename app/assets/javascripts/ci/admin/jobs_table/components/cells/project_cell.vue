<script>
import LinkCell from '~/ci/runner/components/cells/link_cell.vue';

export default {
  components: {
    LinkCell,
  },
  props: {
    job: {
      type: Object,
      required: true,
    },
  },
  computed: {
    projectName() {
      return this.job.pipeline?.project?.fullPath;
    },
    projectUrl() {
      return this.job.pipeline?.project?.webUrl;
    },
  },
};
</script>
<template>
  <div class="gl-truncate">
    <link-cell :href="projectUrl" data-testid="job-project-link">{{ projectName }}</link-cell>
  </div>
</template>
