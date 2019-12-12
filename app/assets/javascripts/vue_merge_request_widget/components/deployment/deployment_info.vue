<script>
import { GlLink, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate.vue';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import MemoryUsage from './memory_usage.vue';
import { MANUAL_DEPLOY, WILL_DEPLOY, RUNNING, SUCCESS, FAILED, CANCELED } from './constants';

export default {
  name: 'DeploymentInfo',
  components: {
    GlLink,
    MemoryUsage,
    TooltipOnTruncate,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [timeagoMixin],
  props: {
    computedDeploymentStatus: {
      type: String,
      required: true,
    },
    deployment: {
      type: Object,
      required: true,
    },
    showMetrics: {
      type: Boolean,
      required: true,
    },
  },
  deployedTextMap: {
    [MANUAL_DEPLOY]: __('Can deploy manually to'),
    [WILL_DEPLOY]: __('Will deploy to'),
    [RUNNING]: __('Deploying to'),
    [SUCCESS]: __('Deployed to'),
    [FAILED]: __('Failed to deploy to'),
    [CANCELED]: __('Canceled deploy to'),
  },
  computed: {
    deployTimeago() {
      return this.timeFormatted(this.deployment.deployed_at);
    },
    deployedText() {
      return this.$options.deployedTextMap[this.computedDeploymentStatus];
    },
    hasDeploymentTime() {
      return Boolean(this.deployment.deployed_at && this.deployment.deployed_at_formatted);
    },
    hasDeploymentMeta() {
      return Boolean(this.deployment.url && this.deployment.name);
    },
    hasMetrics() {
      return Boolean(this.deployment.metrics_url);
    },
    showMemoryUsage() {
      return this.hasMetrics && this.showMetrics;
    },
  },
};
</script>

<template>
  <div class="js-deployment-info deployment-info">
    <template v-if="hasDeploymentMeta">
      <span>{{ deployedText }}</span>
      <tooltip-on-truncate
        :title="deployment.name"
        truncate-target="child"
        class="deploy-link label-truncate"
      >
        <gl-link
          :href="deployment.url"
          target="_blank"
          rel="noopener noreferrer nofollow"
          class="js-deploy-meta gl-font-size-12"
        >
          {{ deployment.name }}
        </gl-link>
      </tooltip-on-truncate>
    </template>
    <span
      v-if="hasDeploymentTime"
      v-gl-tooltip
      :title="deployment.deployed_at_formatted"
      class="js-deploy-time"
    >
      {{ deployTimeago }}
    </span>
    <memory-usage
      v-if="showMemoryUsage"
      :metrics-url="deployment.metrics_url"
      :metrics-monitoring-url="deployment.metrics_monitoring_url"
    />
  </div>
</template>
