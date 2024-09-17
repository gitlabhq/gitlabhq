<script>
import { GlLink } from '@gitlab/ui';

export default {
  components: {
    GlLink,
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
    <gl-link :href="projectUrl" data-testid="job-project-link">{{ projectName }}</gl-link>
  </div>
</template>
