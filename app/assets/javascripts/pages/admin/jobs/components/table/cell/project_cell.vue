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
  <div class="gl-text-truncate">
    <gl-link :href="projectUrl"> {{ projectName }}</gl-link>
  </div>
</template>
