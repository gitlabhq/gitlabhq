<script>
import { GlBadge, GlIcon, GlTooltipDirective as GlTooltip } from '@gitlab/ui';
import { s__ } from '~/locale';
import DeploymentStatusBadge from './deployment_status_badge.vue';

export default {
  components: {
    DeploymentStatusBadge,
    GlBadge,
    GlIcon,
  },
  directives: {
    GlTooltip,
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
    iid() {
      return this.deployment?.iid;
    },
  },
  i18n: {
    latestBadge: s__('Deployment|Latest Deployed'),
    deploymentId: s__('Deployment|Deployment ID'),
  },
};
</script>
<template>
  <div class="gl-display-flex gl-align-items-center gl-gap-x-3">
    <deployment-status-badge v-if="status" :status="status" />
    <gl-badge v-if="latest" variant="info">{{ $options.i18n.latestBadge }}</gl-badge>
    <div
      v-if="iid"
      v-gl-tooltip
      :title="$options.i18n.deploymentId"
      :aria-label="$options.i18n.deploymentId"
    >
      <gl-icon ref="deployment-iid-icon" name="deployments" /> {{ iid }}
    </div>
  </div>
</template>
