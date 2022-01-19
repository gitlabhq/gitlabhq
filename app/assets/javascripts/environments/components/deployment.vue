<script>
import DeploymentStatusBadge from './deployment_status_badge.vue';

export default {
  components: {
    DeploymentStatusBadge,
  },
  props: {
    deployment: {
      type: Object,
      required: true,
    },
  },
  computed: {
    status() {
      return this.deployment?.status;
    },
  },
};
</script>
<template>
  <div>
    <deployment-status-badge v-if="status" :status="status" />
  </div>
</template>
