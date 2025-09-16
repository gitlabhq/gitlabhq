<script>
import { GlLink, GlTruncate } from '@gitlab/ui';
import { __ } from '~/locale';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
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
    GlTruncate,
    TimeAgoTooltip,
  },
  props: {
    computedDeploymentStatus: {
      type: String,
      required: true,
    },
    deployment: {
      type: Object,
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
    deployedText() {
      return this.$options.deployedTextMap[this.computedDeploymentStatus];
    },
    hasDeploymentTime() {
      return Boolean(this.deployment.deployed_at);
    },
    hasDeploymentMeta() {
      return Boolean(this.deployment.url && this.deployment.name);
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
    <time-ago-tooltip
      v-if="hasDeploymentTime"
      :time="deployment.deployed_at"
      data-testid="deployment-time"
    />
  </div>
</template>
