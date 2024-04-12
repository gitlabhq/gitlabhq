<script>
import DeploymentStatusBadge from './deployment_status_badge.vue';

export default {
  components: {
    DeploymentStatusBadge,
  },
  props: {
    status: {
      type: String,
      required: true,
    },
    deploymentJob: {
      type: Object,
      required: false,
      default: null,
    },
    deployment: {
      type: Object,
      required: false,
      default: null,
    },
  },
  computed: {
    path() {
      return (
        this.deployment?.webPath || this.deploymentJob?.webPath || this.deploymentJob?.buildPath
      );
    },
  },
};
</script>
<template>
  <deployment-status-badge :status="status" :href="path" />
</template>
