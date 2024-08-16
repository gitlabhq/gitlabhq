<script>
import { GlLink, GlTooltipDirective, GlTruncate } from '@gitlab/ui';
import { __ } from '~/locale';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import {
  MANUAL_DEPLOY,
  WILL_DEPLOY,
  RUNNING,
  SUCCESS,
  FAILED,
  CANCELED,
  SKIPPED,
} from './constants';

export default {
  name: 'DeploymentInfo',
  components: {
    GlLink,
    MemoryUsage: () => import('./memory_usage.vue'),
    GlTruncate,
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
    [MANUAL_DEPLOY]: __('Can be manually deployed to'),
    [WILL_DEPLOY]: __('Will deploy to'),
    [RUNNING]: __('Deploying to'),
    [SUCCESS]: __('Deployed to'),
    [FAILED]: __('Failed to deploy to'),
    [CANCELED]: __('Canceled deployment to'),
    [SKIPPED]: __('Skipped deployment to'),
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
      <gl-link
        :href="deployment.url"
        target="_blank"
        rel="noopener noreferrer nofollow"
        class="js-deploy-meta gl-pb-1 gl-text-sm"
      >
        <gl-truncate
          class="js-deploy-env-name"
          :text="deployment.name"
          position="middle"
          with-tooltip
        />
      </gl-link>
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
