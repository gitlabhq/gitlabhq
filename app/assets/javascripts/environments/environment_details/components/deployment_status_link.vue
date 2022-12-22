<script>
import DeploymentStatusBadge from '~/environments/components/deployment_status_badge.vue';

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
  },
};
</script>
<template>
  <a v-if="deploymentJob" data-testid="deployment-status-job-link" :href="deploymentJob.webPath">
    <deployment-status-badge :status="status" />
  </a>
  <deployment-status-badge v-else :status="status" />
</template>
