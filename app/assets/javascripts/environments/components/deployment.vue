<script>
import { GlBadge } from '@gitlab/ui';
import { s__ } from '~/locale';
import DeploymentStatusBadge from './deployment_status_badge.vue';

export default {
  components: {
    DeploymentStatusBadge,
    GlBadge,
  },
  props: {
    deployment: {
      type: Object,
      required: true,
    },
    latest: {
      type: Boolean,
      default: false,
      required: false,
    },
  },
  computed: {
    status() {
      return this.deployment?.status;
    },
  },
  i18n: {
    latestBadge: s__('Deployment|Latest Deployed'),
  },
};
</script>
<template>
  <div class="gl-display-flex gl-align-items-center gl-gap-x-3">
    <deployment-status-badge v-if="status" :status="status" />
    <gl-badge v-if="latest" variant="info">{{ $options.i18n.latestBadge }}</gl-badge>
  </div>
</template>
